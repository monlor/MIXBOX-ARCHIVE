#!/bin/sh 
source /etc/mixbox/bin/base
eval `mbdb export aria2`

port=6800
WEBDIR=${mbroot}/apps/${appname}/web
[ -z "${port}" ] && port=6800
[ -z "$path" ] && path="$mbdisk/下载"
aria2url=http://$lanip/backup/log/${appname}
binname=aria2c

open_ports() {
    # 添加bt下载和DHT监听端口
    open_port 6881:6999 tcp
}

set_config() {

	logsh "【$service】" "加载${appname}配置..."
	[ ! -f /etc/aria2.session ] && touch /etc/aria2.session

	[ ! -z "${port}" ] && sed -i "s/^.*rpc-listen-port.*$/rpc-listen-port=${port}/" ${mbroot}/apps/${appname}/config/${appname}.conf

	if [ ! -z "$token" ]; then
		sed -i "s/^.*rpc-secret.*$/rpc-secret=$token/" ${mbroot}/apps/${appname}/config/${appname}.conf
	else
		sed -i "s/^.*rpc-secret.*$/#rpc-secret=/" ${mbroot}/apps/${appname}/config/${appname}.conf
	fi

	sed -i "s#dir.*#dir=$path#" ${mbroot}/apps/${appname}/config/${appname}.conf

	[ ! -d "$path" ] && mkdir -p $path

    # DHT 缓存目录配置
    if [ ! -d "${path}/.aria2" ]; then
        mkdir -p "${path}/.aria2"
        # IPV6默认没有开，可以不用配置
        sed -i "s#.*dht-file-path.*#dht-file-path=${path}/.aria2/dht.dat#" ${mbroot}/apps/${appname}/config/${appname}.conf
        sed -i "s#.*dht-file-path6.*#dht-file-path6=${path}/.aria2/dht6.dat#" ${mbroot}/apps/${appname}/config/${appname}.conf
    fi

    # 自动更新bt-tracker
    list=`curl -s https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best.txt|awk NF|sed ":a;N;s/\n/,/g;ta"`
    if [ ! -z "${list}" ]; then
        sed -i "s#.*bt-tracker.*#bt-tracker=${list}#" ${mbroot}/apps/${appname}/config/${appname}.conf
        logsh "【$service】" "更新bt-tracker"
    fi

	#R3加载库文件
	[ "$xq" == "R3" -o "$xq" == "R1CM" ] && export LD_LIBRARY_PATH=${mbroot}/apps/${appname}/lib:/usr/lib:/lib

	if [ ! -d /tmp/syslogbackup/${appname} ]; then
		logsh "【$service】" "生成${appname}本地web页面"
		mkdir -p /tmp/syslogbackup &> /dev/null
		ln -s $WEBDIR/AriaNG /tmp/syslogbackup/${appname} > /dev/null 2>&1
	fi
	#添加定时重启任务
	cru a ${appname} "0 6 * * * ${mbroot}/apps/${appname}/scripts/${appname}.sh restart"

}

start () {

	result=$(ps | grep ${mbroot}/apps/${appname}/bin/${appname} | grep -v grep | wc -l)
    	if [ "$result" != '0' ];then
		logsh "【$service】" "${appname}已经在运行！"
		exit 1
	fi
	logsh "【$service】" "正在启动${appname}服务... "

	set_config

	open_port
    write_firewall_start

    if [ ! -f ${mbroot}/apps/${appname}/bin/${appname} ]; then
		bincheck ${binname} 
    	[ $? -eq 0 ] && ln -sf $(which $binname) ${mbroot}/apps/${appname}/bin/${appname} 
	fi
	daemon ${mbroot}/apps/${appname}/bin/${appname} --conf-path=${mbroot}/apps/${appname}/config/${appname}.conf -D -l ${mbroot}/var/log/${appname}.log
	if [ $? -ne 0 ]; then
    	logsh "【$service】" "启动${appname}服务失败！"
    else
        logsh "【$service】" "启动${appname}服务完成！"
        logsh "【$service】" "访问[$aria2url]管理服务"
		[ -z "$token" ] && tokentext="" || tokentext=token:"$token"@
		logsh "【$service】" "jsonrpc地址:http://"$tokentext""$lanip":"${port}"/jsonrpc"
    fi

}

stop () {

	logsh "【$service】" "正在停止${appname}服务... "
	close_port
	remove_firewall_start
	killall -9 ${appname} &> /dev/null
	
	destroy
}

destroy() {
	if [ "$enable" == '0' ]; then
		[ -d /tmp/syslogbackup/${appname} ] && rm -rf /tmp/syslogbackup/${appname}
		cru d ${appname}
	fi
}


status() {

	result=$(pssh | grep ${mbroot}/apps/${appname}/bin/${appname} | grep -v grep | wc -l)
	if [ "$result" == '0' ]; then
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

