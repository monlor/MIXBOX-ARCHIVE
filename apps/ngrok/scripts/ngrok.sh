#!/bin/sh 
source /etc/mixbox/bin/base
eval `mbdb export ngrok`

set_config() {

	local cmdstr=""
	ser_token=$(mbdb get ${appname}.main.ser_token)
	while read line
	do 
		[ `echo ${line} | grep -c "^#"` -ne 0 ] && continue 
		type=`echo ${line} | awk -F ',' '{print$2}'`
		lhost=`echo ${line} | awk -F ',' '{print$3}'`
		lport=`echo ${line} | awk -F ',' '{print$4}'`
		rport=`echo ${line} | awk -F ',' '{print$5}'`
		domain=`echo ${line} | awk -F ',' '{print$6}'`
		if [ "$type" == "tcp" ]; then
			cmdstr="$cmdstr -AddTun[Type:$type,Lhost:$lhost,Lport:$lport,Rport:$rport]"
		else
			if [ `echo $domain | grep "\." | wc -l` -ne 0 ]; then
				cmdstr="$cmdstr -AddTun[Type:$type,Lhost:$lhost,Lport:$lport,Hostname:$domain]" 
			else
				cmdstr="$cmdstr -AddTun[Type:$type,Lhost:$lhost,Lport:$lport,Sdname:$domain]" 
			fi
		fi
	done < ${mbroot}/apps/${appname}/config/ngroklist
	[ -z "$cmdstr" ] || cmdstr="${mbroot}/apps/${appname}/bin/${appname} -SER[Shost:$ser_host,Sport:$ser_port,Password:$ser_token]$cmdstr"
	echo $cmdstr

}

start () {

	result=$(ps | grep ${mbroot}/apps/${appname}/bin/${appname} | grep -v grep | wc -l)
    	if [ "$result" != '0' ];then
		logsh "【$service】" "${appname}已经在运行！"
		exit 1
	fi
	logsh "【$service】" "正在启动${appname}服务... "
	[ -z "$ser_host" -o -z "$ser_port" ] && logsh "【$service】" "${appname}未配置" && exit
	runstr=`set_config`
	# open_port
    # write_firewall_start
	daemon $runstr
	if [ $? -ne 0 ]; then
            logsh "【$service】" "启动${appname}服务失败！"
    else
            logsh "【$service】" "启动${appname}服务完成！"
    fi

}

stop () {

	logsh "【$service】" "正在停止${appname}服务... "
	
	killall -9 ${appname} &> /dev/null
	# 

}


status() {

	result=$(pssh | grep ${mbroot}/apps/${appname}/bin/${appname} | grep -v grep | wc -l)
	if [ "$result" == '0' ]; then
		status="未运行|0"
	else
		status="运行服务器: $ser_host:$ser_port|1"
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


