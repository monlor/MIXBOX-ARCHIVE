#!/bin/sh 
source /etc/mixbox/bin/base
eval `mbdb export pptpd`
source "$(mbdb get mixbox.main.path)"/apps/entware/scripts/functions.sh
port=1723

open_ports () {
    iptables -I FORWARD -i ppp+ -j ACCEPT -m comment --comment "mixbox-${appname}" &> /dev/null
    open_port
}

add(){
    [ -z "$1" -o -z "$2" ] && exit 1
    sed -i "/^$1/"d /etc/ppp/chap-secrets 
    echo "$1    pptpd   $2  *   #tools" >> /etc/ppp/chap-secrets 
}
del(){
    [ -z "$1" ] && exit 1
    sed -i "/^$1/{/tools$/d}" /etc/ppp/chap-secrets
    cat /tmp/pptp_connected | grep $1 | awk -F " " '{print $7}' |  xargs kill -9
    sed -i "/$1/"d /tmp/pptp_connected
}

detect_entware() {
    result1=$(mbdb show entware)
    result2=$(ls /opt | grep etc)
    if [ -z "$result1" ] || [ -z "$result2" ]; then 
        logsh "【$service】" "检测到【Entware】服务未启动或未安装"
        end
    else
        result3=$(echo $PATH | grep opt)
        [ -z "$result3" ] && export PATH=/opt/bin:/opt/sbin:$PATH
    fi
}

install_entware_app() {
    for i in $@; do
        result=$(/opt/bin/opkg list-installed | grep -c "^$i")
        if [ "$result" == '0' ]; then
            /opt/bin/opkg install $i 
            [ $? -ne 0 ] && logsh "【$service】" "程序$i安装失败！" && exit 1
        fi
    done
}

start() {

    [ -n "$(pidof ${appname})" ] && logsh "【$service】" "${appname}已经在运行！" && exit 1
    logsh "【$service】" "正在启动${appname}服务... "
    # cru a "${appname}" "0 6 * * * ${mbroot}/apps/${appname}/scripts/${appname}.sh restart"
    # Scripts Here
    # 检查entware
    detect_entware
    
    install_entware_app ${appname}

    cp -rf ${mbroot}/apps/${appname}/config/pptpd.conf /tmp/pptpd.conf
    cp -rf ${mbroot}/apps/${appname}/config/options.pptpd /tmp/options.pptpd
    
    echo "localip "$localip >> /tmp/pptpd.conf
    network=$(echo $localip | awk -F "." '{print $1"."$2"."$3"."}')
    echo "remoteip " $network$ip_min"-"$ip_max >> /tmp/pptpd.conf
    echo "ms-dns "$dns1 >> /tmp/options.pptpd
    echo "ms-dns "$dns2 >> /tmp/options.pptpd
    echo "ms-wins "$lanip >> /tmp/options.pptpd
    
    auto_start_enable ${appname}
    open_ports
    write_firewall_start
    daemon /opt/sbin/pptpd -c /tmp/pptpd.conf -o /tmp/options.pptpd 
    if [ $? -ne 0 ]; then
        logsh "【$service】" "启动${appname}服务失败！" && end
    else
        logsh "【$service】" "启动${appname}服务完成！"
    fi
        
}

stop() {

    logsh "【$service】" "正在停止${appname}服务... "
    [ "$enable" == '0' ] && destroy
    close_port
    remove_firewall_start
    rm -rf {${mbtmp}}/*pptp*
    killall -9 ${appname} &> /dev/null
    # ps  |grep pptpd | grep -v grep | grep -v {pptpd} | grep -v restart | awk '{print $1}' | xargs kill -9

}

destroy() {
        
    auto_start_disable ${appname}
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
    mbdb set ${appname}.main.status="$status" 
}

case "$1" in
    start) start ;;
    stop) stop ;;
    restart) stop; start ;;
    reload) close_port && open_ports ;;
    status) status ;;
    add) add "$2" "$3" ;;
    del) del "$2" ;;
esac


