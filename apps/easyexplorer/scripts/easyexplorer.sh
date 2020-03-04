#!/bin/sh 
source /etc/mixbox/bin/base
eval `mbdb export easyexplorer`

path=$(mbdb get ${appname}.main.share_path) || path="$mbdisk"
port=$(mbdb get ${appname}.main.port) || port=8890


set_config() {

	[ ! -d "$path" ] && mkdir -p $path 
	token=$(mbdb get ${appname}.main.token)
	[ -z "$token" ] && logsh "【$service】" "未配置${appname}的密钥" && exit

}

start () {

	if [ "$model" != "arm" ]; then
		logsh "【$service】" "${appname}服务仅支持arm路由器，准备卸载" 
		${mbroot}/scripts/appmanage.sh del ${appname} 
		exit
	fi
	result=$(ps | grep ${mbroot}/apps/${appname}/bin | grep -v grep | wc -l)
    	if [ "$result" != '0' ];then
		logsh "【$service】" "${appname}已经在运行！"
		exit 1
	fi
	logsh "【$service】" "正在启动${appname}服务... "

	set_config
	
	# open_port
    # write_firewall_start
	
	daemon ${mbroot}/apps/${appname}/bin -fe 0.0.0.0:${port} -u $token -share $path -c ${mbtmp}
	if [ $? -ne 0 ]; then
        logsh "【$service】" "启动${appname}服务失败！"
    else
        logsh "【$service】" "启动${appname}服务完成！"
        logsh "【$service】" "请在浏览器中访问[http://$lanip:${port}]"
    fi

}

stop () {

	logsh "【$service】" "正在停止${appname}服务... "
	service_stop ${mbroot}/apps/${appname}/bin
	killall -9 ${appname} &> /dev/null

}


status() {

	result=$(pssh | grep ${mbroot}/apps/${appname}/bin | grep -v grep | wc -l)
	if [ "$result" == '0' ]; then
		status="未运行|0"
	else
		status="运行端口号：${port}，共享目录: $path|1"
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

