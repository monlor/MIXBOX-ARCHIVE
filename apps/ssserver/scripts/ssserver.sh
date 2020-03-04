#!/bin/sh 
source /etc/mixbox/bin/base
eval `mbdb export ssserver`
binname="shadowsocks-libev"

start() {

    [ -n "$(pidof ss-server)" ] && logsh "【$service】" "${appname}已经在运行！" && exit 1
    logsh "【$service】" "正在启动${appname}服务... "
    # cru a "${appname}" "0 6 * * * ${mbroot}/apps/${appname}/scripts/${appname}.sh restart"
    # Scripts Here
    
    cat > ${mbroot}/apps/${appname}/config/ss.json <<-EOF
{
    "server":"0.0.0.0",
    "server_port":${port},
    "password":"$password",
    "timeout":300,
    "user":"nobody",
    "method":"$method",
    "nameserver":"223.5.5.5",
    "mode":"tcp_and_udp"
}
EOF
    open_port
    write_firewall_start
    daemon ${mbroot}/apps/${appname}/bin/ss-server -c ${mbroot}/apps/${appname}/config/ss.json
    logsh "【$service】" "启动${appname}服务完成！"
        
}

stop() {

    logsh "【$service】" "正在停止${appname}服务... "
    [ "$enable" == '0' ] && destroy
    close_port
    remove_firewall_start
    kill -9 "$(pidof ss-server)" &> /dev/null

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

    if [ -n "$(pidof ss-server)" ]; then
            status="运行端口号：${port}|1"
    else
            status="未运行|0"
    fi
    mbdb set ${appname}.main.status="$status" 
}

case "$1" in
    start) start ;;
    stop) stop ;;
    restart) stop; start ;;
    reload) close_port && open_port ;;
    status) status ;;
esac


