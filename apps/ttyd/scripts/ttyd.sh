#!/bin/sh
source /etc/mixbox/bin/base
eval `mbdb export webshell`

port=${port:-6000}

start () {

	[ -n "$(pidof ${appname})" ] && logsh "【$service】" "${appname}已经在运行！" && exit 1
	logsh "【$service】" "正在启动${appname}服务... "
	open_port
	write_firewall_start
	daemon ${mbroot}/apps/${appname}/bin/${appname} -p ${port} ash
	if [ $? -ne 0 ]; then
		logsh "【$service】" "启动${appname}服务失败！"
	else
		logsh "【$service】" "启动${appname}服务完成！"
		logsh "【$service】" "请在浏览器访问http://$lanip:${port}"
	fi

}

stop () {

	logsh "【$service】" "正在停止${appname}服务... "
	close_port
	remove_firewall_start
	killall -9 ${appname} &> /dev/null

}


status() {

	if [ -n "$(pidof ${mbroot}/apps/${appname}/bin/${appname})" ]; then
		status="未运行|0"
	else
		status="运行端口号: ${port}|1"
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


