#!/bin/sh 
source /etc/mixbox/bin/base
eval `mbdb export frpc`

# port=
[ -z "$tcp_mux" ] && tcp_mux="true"
[ -z "$user" ] && user="mixbox"
[ -z "$protocol" ] && protocol="tcp"
[ -z "$runver" ] && runver=`${mbroot}/apps/${appname}/bin/${appname} -v`

set_config() {

	logsh "【$service】" "生成${appname}配置文件"
	result=$(mbdb show ${appname}.main | grep server | wc -l)
	if [ "$result" == '0' ]; then
		logsh "【$service】" "${appname}配置出现问题！"
		exit
	fi

	if [ "$(${mbroot}/apps/${appname}/bin/${appname} -v)" != "$runver" ]; then
		logsh "【$service】" "检测到版本号更换，重新下载${appname}程序..."
		wgetsh "${mbroot}/apps/${appname}/bin/${appname}" "$mburl/appsbin/frp-bin/$runver/frpc_${model}"
		[ "$?" -ne 0 ] && logsh "【$service】" "下载${appname}程序失败！" && exit 1
 	fi  
	
	token=$(mbdb get ${appname}.main.token)
	cat > ${mbroot}/apps/${appname}/config/${appname}.conf <<-EOF
	[common]
	server_addr = $server
	server_port = $server_port
	log_file = ${mbroot}/var/log/${appname}.log
	log_level = info
	log_max_days = 1
	EOF
	if [ "$runver" != "0.9.3" ]; then
		echo "token = $token" >> ${mbroot}/apps/${appname}/config/${appname}.conf
		echo "tcp_mux = $tcp_mux" >> ${mbroot}/apps/${appname}/config/${appname}.conf
		echo "user = $user" >> ${mbroot}/apps/${appname}/config/${appname}.conf
		echo "protocol = $protocol" >> ${mbroot}/apps/${appname}/config/${appname}.conf
	else
		echo "privilege_token = $token" >> ${mbroot}/apps/${appname}/config/${appname}.conf
	fi
	mbdb show ${appname}.info | while read line
	do
		[ -z "${line}" ] || [ ${line:0:1} == "#" ] && continue
		echo >> ${mbroot}/apps/${appname}/config/${appname}.conf
		name="$(echo ${line} | cut -d'=' -f1)"
		info="$(echo ${line} | cut -d'=' -f2)"
		echo "[$name]" >> ${mbroot}/apps/${appname}/config/${appname}.conf
		type=`cutsh $info 1`
		[ "$type" != "http" -a "$type" != "tcp" ] &&  logsh "【$service】" "节点$name类型设置错误！" && exit
		echo "type = $type" >> ${mbroot}/apps/${appname}/config/${appname}.conf
		echo "local_ip = `cutsh $info 2`" >> ${mbroot}/apps/${appname}/config/${appname}.conf
		echo "local_port = `cutsh $info 3`" >> ${mbroot}/apps/${appname}/config/${appname}.conf
		if [ "$type" == "tcp" -o "$type" == "udp" ]; then
			echo "remote_port = `cutsh $info 4`" >> ${mbroot}/apps/${appname}/config/${appname}.conf
			logsh "【$service】" "加载${appname}配置:【$name】启动为tcp/udp模式,端口号:[`cutsh ${line} 4`]"
		fi
		if [ "$type" == "http" -o "$type" == "https" ]; then
			domain=`cutsh $info 5`
			if [ `echo $domain | grep "\." | wc -l` -eq 0 ]; then
				echo "subdomain = $domain" >> ${mbroot}/apps/${appname}/config/${appname}.conf
				logsh "【$service】" "加载${appname}配置:【$name】启动为http/https子域名模式,域名:[$domain]"
			else
				echo "custom_domain = $domain" >> ${mbroot}/apps/${appname}/config/${appname}.conf
				logsh "【$service】" "加载${appname}配置:【$name】启动为http/https自定义域名模式,域名:[$domain]"
			fi
		fi
		echo "use_encryption = true" >> ${mbroot}/apps/${appname}/config/${appname}.conf
		echo "use_gzip = false" >> ${mbroot}/apps/${appname}/config/${appname}.conf
	done

}

start () {

	result=$(ps | grep ${mbroot}/apps/${appname}/bin/${appname} | grep -v grep | wc -l)
   	if [ "$result" != '0' ];then
		logsh "【$service】" "${appname}已经在运行！"
		exit 1
	fi
	logsh "【$service】" "正在启动${appname}服务... "
	cru a "${appname}" "0 6 * * * ${mbroot}/apps/${appname}/scripts/${appname}.sh restart"
	set_config
	
	# open_port
    # write_firewall_start
	daemon ${mbroot}/apps/${appname}/bin/${appname} -c ${mbroot}/apps/${appname}/config/${appname}.conf
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
	rm -rf ${mbroot}/apps/${appname}/config/${appname}.conf > /dev/null 2>&1
	[ "$enable" == '0' ] && destroy

}

destroy() {

	cru d "${appname}"

}


status() {

	result=$(pssh | grep ${mbroot}/apps/${appname}/bin/${appname} | grep -v grep | wc -l)
	if [ "$result" == '0' ]; then
		status="未运行|0"
	else
		status="运行服务器: $server:$server_port|1"
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
