#!/bin/sh 
source /etc/mixbox/bin/base
eval `mbdb export frps`

open_ports() {
    [ -n "${port}" ] && open_port ${port}
    [ -n "$udp_port" ] && open_port $udp_port
    [ -n "$http_port" ] && open_port $http_port
    [ -n "$https_port" ] && open_port $https_port
    [ -n "$dashboard_port" ] && open_port $dashboard_port
}

start() {

    [ -n "$(pidof ${appname})" ] && logsh "【$service】" "${appname}已经在运行！" && exit 1
    logsh "【$service】" "正在启动${appname}服务... "
    # cru a "${appname}" "0 6 * * * ${mbroot}/apps/${appname}/scripts/${appname}.sh restart"
    # Scripts Here
    open_ports
    write_firewall_start
	cat > ${mbroot}/apps/${appname}/config/${appname}.conf <<-EOF
[common]
bind_addr = 0.0.0.0
bind_port = ${port}
bind_udp_port = $udp_port
`[ "$kcp" = '1' ] && echo "kcp_bind_port = ${port}"`
vhost_http_port = $http_port
vhost_https_port = $https_port
dashboard_addr = 0.0.0.0
`[ "$dashboard" = '1' ] && echo "dashboard_port = $dashboard_port"`
`[ "$dashboard" = '1' ] && echo "dashboard_user = $dashboard_user"`
`[ "$dashboard" = '1' ] && echo "dashboard_pwd = $dashboard_pwd"`
log_file = /var/log/${appname}.log
log_level = info
log_max_days = 3
token = $token
#max_pool_count = 5
#max_ports_per_client = 0
#authentication_timeout = 900
`[ -n "$subdomain" ] && echo "subdomain_host = $subdomain"`
tcp_mux = true
EOF
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
        close_port
        remove_firewall_start
        killall -9 ${appname} &> /dev/null
        

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
        result=$(iptables -S | grep "mixbox-${appname}")
        if [ -n "$(pidof ${appname})" -a -n "$result" ]; then
                status="运行端口号：${port}|1"
        else
                status="未运行|0"
        fi
        mbdb set $appname.main.status="$status" 
}

case "$1" in
    start) start ;;
    stop) stop ;;
    restart) stop; start ;;
    reload) close_port && open_ports ;;
    status) status ;;
esac
