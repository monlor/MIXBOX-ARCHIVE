#!/bin/sh 
source /etc/mixbox/bin/base
eval `mbdb export smartdns`

[ -z "${port}" ] && port=535


set_iptable()
{
    IPS="`ifconfig | grep "inet addr" | grep -v ":127" | grep "Bcast" | awk '{print $2}' | awk -F: '{print $2}'`"
    for IP in $IPS
    do
            [ -z "$(iptables -t nat -S | grep "${appname}"-"$IP")" ] && iptables -t nat -A PREROUTING -p udp -d $IP --dport 53 -m comment --comment "${appname}"-"$IP" -j REDIRECT --to-ports ${port} 
    done

}

clear_iptable()
{
    eval `iptables -t nat -S | grep "${appname}"- | sed -e 's/-A/iptables -t nat -D/g' | sed -e 's/\$/;/g'`
}

set_dnsmasq() {
    uci set dhcp.@dnsmasq[0].local=127.0.0.1#$port
    uci commit 
    /etc/init.d/dnsmasq reload
}

reset_dnsmsq() {
    uci set dhcp.@dnsmasq[0].local=/lan/
    uci commit 
    /etc/init.d/dnsmasq reload
}

set_default_dns() {
    cat >> ${mbroot}/apps/${appname}/config/${appname}.conf <<-EOF
server 223.5.5.5:53
server 114.114.114.114:53
server 180.153.225.136:53
server 180.76.76.76:53
server 101.226.4.5:53
server 8.8.8.8:53
server 208.67.220.220:53
server 1.1.1.1:53
server 117.50.11.11:53
server 119.29.29.29:53
EOF
}

start() {

    [ -n "$(pidof ${appname})" ] && logsh "【$service】" "${appname}已经在运行！" && exit 1
    logsh "【$service】" "正在启动${appname}服务... "
    # cru a "${appname}" "0 6 * * * ${mbroot}/apps/${appname}/scripts/${appname}.sh restart"
    # Scripts Here
    # open_port
    write_firewall_start
    # 修改上游服务器
    sed -i '/^server/d' ${mbroot}/apps/${appname}/config/${appname}.conf
    if [ -z "$(mbdb values ${appname}.info)" ]; then
            logsh "【$service】" "未添加自定义DNS服务器！"
    else
            mbdb values ${appname}.info >> ${mbroot}/apps/${appname}/config/${appname}.conf
    fi
    [ "$default_dns" = "1" ] && set_default_dns
    # 修改端口号
    sed -i '/bind \[::\]:/d' ${mbroot}/apps/${appname}/config/${appname}.conf
    echo "bind [::]:${port}" >> ${mbroot}/apps/${appname}/config/${appname}.conf
    logsh "【$service】" "添加dnsmasq上游解析dns中..."
    set_dnsmasq &> /dev/null
    [ $? -ne 0 ] && logsh "【$service】" "未监测到dnsmasq，尝试添加iptables规则..." && set_iptable

    daemon ${mbroot}/apps/${appname}/bin/${appname} -c ${mbroot}/apps/${appname}/config/${appname}.conf
    if [ $? -ne 0 ]; then
        logsh "【$service】" "启动${appname}服务失败！"
    else
        logsh "【$service】" "启动${appname}服务完成！"
    fi
        
}

stop() {

    logsh "【$service】" "正在停止${appname}服务... "
    [ "$enable" == '0' ] && destroy
    
    killall -9 ${appname} &> /dev/null
    clear_iptable &> /dev/null
    reset_dnsmsq &> /dev/null
    remove_firewall_start
    # 

}

destroy() {
        
    # End app, Scripts here 
    # cru d "${appname}"
    return

}

end() {

    mbdb set $appname.main.enable=0
    
    stop && exit 1

}

status() {

    if [ -n "$(pidof ${appname})" ]; then
            status="运行中|1"
    else
            status="未运行|0"
    fi
    mbdb set $appname.main.status="$status" 
}

case "$1" in
    start) start ;;
    stop) stop ;;
    restart) stop; start ;;
    reload) clear_iptable && set_iptable ;;
    status) status ;;
esac
