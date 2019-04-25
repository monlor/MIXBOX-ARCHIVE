#!/bin/sh 
source /etc/mixbox/bin/base
eval `mbdb export verysync`

CONF="$mbdisk"/."${appname}"
port=$(mbdb get ${appname}.main.port) || port=8886

open_ports() {
	open_port ${port} tcp
	open_port 22330 tcp
	open_port 22027,22037,15298,22027,22037,7123 udp

}

start () {

	result=$(ps | grep ${mbroot}/apps/${appname}/bin/${appname} | grep -v grep | wc -l)
   	if [ "$result" != '0' ];then
		logsh "【$service】" "${appname}已经在运行！"
		exit 1
	fi
	logsh "【$service】" "正在启动${appname}服务... "
	cru a "${appname}" "0 6 * * * ${mbroot}/apps/${appname}/scripts/${appname}.sh restart"
	[ -f "${mbroot}/apps/${appname}/bin/${appname}".old ] && rm -rf "${mbroot}/apps/${appname}/bin/${appname}".old
	[ ! -d "${CONF}" ] && mkdir ${CONF}
	open_ports
    write_firewall_start
	daemon ${mbroot}/apps/${appname}/bin/${appname} -home "${CONF}" -gui-address :${port} -no-browser -logfile ${mbroot}/var/log/${appname}.log
	if [ $? -ne 0 ]; then
            logsh "【$service】" "启动${appname}服务失败！"
    else
            logsh "【$service】" "启动${appname}服务完成！"
            logsh "【$service】" "请在浏览器中访问[http://$lanip:${port}]"
    fi
	

}

stop () {

	logsh "【$service】" "正在停止${appname}服务... "
	close_port
	remove_firewall_start
	killall -9 ${appname} &> /dev/null
	logsh "【$service】" "卸载插件后可删除${CONF}文件夹"
	[ "$enable" == '0' ] && destroy

}

destroy() {

	cru d "${appname}"

}


status() {

	if [ -n "$(pidof $appname)" ]; then
		status="运行端口号: ${port}|1"
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
