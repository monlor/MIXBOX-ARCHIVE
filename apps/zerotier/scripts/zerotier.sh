#!/bin/sh 
source /etc/mixbox/bin/base
eval `mbdb export zerotier`
source /etc/mixbox/apps/entware/scripts/functions.sh

OPKG="/opt/bin/opkg"
ZTO="/opt/bin/zerotier-one"
ZTC="/opt/bin/zerotier-cli"

start() {

    [ -n "$(pidof "${appname}"-one)" ] && logsh "【$service】" "${appname}已经在运行！" && exit 1
    logsh "【$service】" "正在启动${appname}服务... "
    cru a "${appname}" "0 6 * * * ${mbroot}/apps/${appname}/scripts/${appname}.sh restart"
    # Scripts Here
    [ -z "$networkid" ] && logsh "【$service】" "检测到未设置网络ID！关闭插件！" && end
    if [ "$(mbdb get entware.main.enable)" == '0' ]; then
            logsh "【$service】" "检测到Entware服务未启用或未安装！关闭插件！"
            end
    fi
    if [ -z "$($OPKG list-installed | grep ${appname})" ]; then
            logsh "【$service】" "正在opkg安装${appname}程序..."
            $OPKG install ${appname}
            [ $? -ne 0 ] && logsh "【$service】" "安装失败！请检查Entware环境！" && exit 1
    fi
    #添加entware识别
    auto_start_enable
    # open_port
    # write_firewall_start
    daemon $ZTO -d && sleep 1 && $ZTC join $networkid &> /dev/null
    if [ $? -ne 0 ]; then
        logsh "【$service】" "启动${appname}服务失败！"
    else
        logsh "【$service】" "启动${appname}服务完成！"
    fi
        
}

stop() {

    logsh "【$service】" "正在停止${appname}服务... "
    service_stop $ZTO &> /dev/null
    kill -9 "$(pidof "${appname}"-one)"
    # 
    [ "$enable" == '0' ] && destroy

}

destroy() {
        
    # End app, Scripts here 
    cru d "${appname}"
    #清除entware识别
    auto_start_disable
    return

}

end() {

    mbdb set $appname.main.enable=0
    
    stop && exit 1

}

status() {

    ipaddr=$(ifconfig | grep -A8 ^zt | grep "inet addr" | awk '{print$2}' | cut -d':' -f2)
    if [ -n "$(pidof "${appname}"-one)" ]; then
            port="$(cat /opt/var/lib/zerotier-one/zerotier-one.port)" &> /dev/null
            [ -n "$(echo $ipaddr | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}")" ] && iptext="，内网IP地址：$ipaddr" || iptext="，获取内网IP地址中"
            status="运行端口号：${port}$iptext|1"
    else
            status="未运行|0"
    fi
    mbdb set $appname.main.status="$status" 
}

case "$1" in
    start) start ;;
    stop) stop ;;
    restart) stop; start ;;
    reload) stop; start ;;
    status) status ;;
esac

