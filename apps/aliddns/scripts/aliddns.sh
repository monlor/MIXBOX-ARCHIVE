#!/bin/sh 
source /etc/mixbox/bin/base
eval `mbdb export aliddns`

start() {

    # [ -n "$(pidof ${appname})" ] && logsh "【$service】" "${appname}已经在运行！" && exit 1
    logsh "【$service】" "正在启动${appname}服务... "
    
    # Scripts Here
    # open_port
    # write_firewall_start
    [ -z "$app_key" -o -z "$app_secret" -o -z "$domain" ] && logsh "【$service】" "访问ID或密钥或域名为空！" && exit 1
    [ -z "$time" ] && time=10
    
    cru a "${appname}" "*/$time * * * * ${mbroot}/apps/${appname}/scripts/${appname}.sh restart"
    daemon ${mbroot}/apps/${appname}/bin/${appname} --id "$app_key" --secret "$app_secret" auto-update --domain "$domain"
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

}

destroy() {
        
    # End app, Scripts here 
    cru d "${appname}"
    return

}

end() {

    mbdb set $appname.main.enable=0
    
    stop && exit 1

}

status() {

    if [ -n "$(cru l | grep ${appname})" ]; then
            status="更新域名：$domain|1"
    else
            status="未运行|0"
    fi
    mbdb set $appname.main.status="$status" 
}

case "$1" in
    start) start ;;
    stop) stop ;;
    restart) stop; start ;;
    reload) close_port && open_port ;;
    status) status ;;
esac


