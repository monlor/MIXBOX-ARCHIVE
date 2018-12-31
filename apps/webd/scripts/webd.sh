#!/bin/sh 
eval `mbdb export webd`
source "$(mbdb get mixbox.main.path)"/bin/base

start() {

    [ -n "$(pidof ${appname})" ] && logsh "【$service】" "${appname}已经在运行！" && exit 1
    logsh "【$service】" "正在启动${appname}服务... "
    # cru a "${appname}" "0 6 * * * ${mbroot}/apps/${appname}/scripts/${appname}.sh restart"
    # Scripts Here
    
    # open_port
    # write_firewall_start
    [ ! -d "$path" ] && mkdir -p "$path"
    daemon ${mbroot}/apps/${appname}/bin/${appname} -l "$port" -w "$path"
    if [ $? -ne 0 ]; then
        logsh "【$service】" "启动${appname}服务失败！" && end
    else
        logsh "【$service】" "启动${appname}服务完成！"
        logsh "【$service】" "请在浏览器打开地址：http://$lanip:$port"
    fi
        
}

stop() {

    logsh "【$service】" "正在停止${appname}服务... "
    [ "$enable" == '0' ] && destroy
    # close_port
    # remove_firewall_start
    killall -9 ${appname} &> /dev/null

}

destroy() {
        
    # End app, Scripts here 
    # cru d "${appname}"
    return

}

end() {

    mbdb set ${appname}.main.enable=0
    stop && exit 1

}

status() {

    if [ -n "$(pidof ${appname})" ]; then
            status="运行端口号：$port|1"
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

