#!/bin/sh 
source "$(mbdb get mixbox.main.path)"/bin/base
eval `mbdb export dropbear`

[ -z "${port}" ] && port=1022

get_config() {

    logsh "【$service】" "检查${appname}配置文件中..."
    [ ! -f ${mbroot}/apps/${appname}/config/dropbear_rsa_host_key -a ! -f /etc/dropbear/dropbear_rsa_host_key ] && logsh "【$service】" "缺失证书文件无法启动！" && exit 1
    [ ! -f  ${mbroot}/apps/${appname}/config/dropbear_dss_host_key -a ! -f /etc/dropbear/dropbear_dss_host_key ] && logsh "【$service】" "缺失证书文件无法启动！" && exit 1
    [ ! -f ${mbroot}/apps/${appname}/bin/${appname} ] && cp -rf /usr/sbin/dropbear ${mbroot}/apps/${appname}/bin/${appname}
    # [ ! -f ${mbroot}/apps/${appname}/bin/dropbearkey ] && cp -rf /usr/bin/dropbearkey ${mbroot}/apps/${appname}/bin/dropbearkey
    [ ! -f ${mbroot}/apps/${appname}/config/dropbear_rsa_host_key ] && cp -rf /etc/dropbear/dropbear_rsa_host_key ${mbroot}/apps/${appname}/config/dropbear_rsa_host_key
    [ ! -f ${mbroot}/apps/${appname}/config/dropbear_dss_host_key ] && cp -rf /etc/dropbear/dropbear_dss_host_key ${mbroot}/apps/${appname}/config/dropbear_dss_host_key

}

start() {

    logsh "【$service】" "正在启动${appname}服务... "
    # cru a "${appname}" "0 6 * * * ${mbroot}/apps/${appname}/scripts/${appname}.sh restart"
    # Scripts Here
    logsh "【$service】" "服务启动端口号为：${port}"
    get_config
    if [ "$modify_passwd" = '1' -a -n "$rootpasswd" ]; then
        logsh "【$service】" "系统root用户密码将修改为：$rootpasswd"
        echo -e "${rootpasswd}\n${rootpasswd}" | passwd root
    fi
    open_port
    write_firewall_start
    ${mbroot}/apps/${appname}/bin/${appname} -p ${port} -d ${mbroot}/apps/${appname}/config/dropbear_dss_host_key -r ${mbroot}/apps/${appname}/config/dropbear_rsa_host_key -b ${mbroot}/apps/${appname}/config/banner
    logsh "【$service】" "启动${appname}服务完成！"
    sleep 1
    kill -9 "$(pssh | grep ${mbroot}/apps/${appname}/bin/${appname} | grep -Ev "[ ]+${port}[ ]+" | awk '{print$1}' | tr '\n' ' ')" && sleep 1

        
}

stop() {

    logsh "【$service】" "正在停止${appname}服务... "
    [ "$enable" == '0' ] && destroy
    close_port
    remove_firewall_start

}

destroy() {
        
    # End app, Scripts here 
    # cru d "${appname}"
    logsh "【$service】" "如果终止${appname}将会在重启后生效！"
    # kill -9 "$(pssh | grep ${mbroot}/apps/${appname}/bin/${appname} | awk '{print$1}' | tr '\n' ' ')" && sleep 1
    return

}

end() {

    mbdb set $appname.main.enable=0
    stop && exit 1

}

status() {

    if [ -n "$(pssh | grep ${mbroot}/apps/${appname}/bin/${appname})" ]; then
            status="运行端口号：${port}|1"
    else
            status="未运行|0"
    fi
    mbdb set ${appname}.main.status="$status" 
}

case "$1" in
    start) start ;;
    stop) stop ;;
    restart) stop; start; ;;
    reload) close_port && open_port ;;
    status) status ;;
esac


