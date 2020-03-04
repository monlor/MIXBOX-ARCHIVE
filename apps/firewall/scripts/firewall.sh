#!/bin/sh 
source /etc/mixbox/bin/base
eval `mbdb export firewall`

# port=1688 

open_ports() {

	logsh "【$service】" "加载${appname}配置"
	[ -z "`mbdb keys $appname.openport`" ] && logsh "【$service】" "未添加${appname}配置！" && exit
	mbdb keys $appname.openport | while read line
	do
		name="${line}"
		port=$(mbdb get $appname.openport.$name)
		[ -z "$name" -o -z "${port}" ] && return 1
		logsh "【$service】" "开放$name的端口号: ${port}"
		open_port ${port}
	done
	return 0
}

start () {

	result=$(ps | grep ${mbroot}/apps/${appname}/bin/${appname} | grep -v grep | wc -l)
    	if [ "$result" != '0' ];then
		logsh "【$service】" "${appname}已经在运行！"
		exit 1
	fi
	logsh "【$service】" "正在启动${appname}服务... "

	open_ports
    write_firewall_start

	status
    logsh "【$service】" "启动${appname}服务完成！"
        

}

stop () {

	logsh "【$service】" "正在停止${appname}服务... "
	close_port
	remove_firewall_start

}


status() {

	result1=$(iptables -S | grep -c "mixbox-${appname}")
	if [ "$result1" != '0' ]; then
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
    reload) close_port && open_ports ;;
    status) status ;;
esac
