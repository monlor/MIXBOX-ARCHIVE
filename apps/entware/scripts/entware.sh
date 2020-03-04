#!/bin/sh 
source /etc/mixbox/bin/base
eval `mbdb export entware`

# port=
BIN=/opt/etc/init.d/rc.unslung
[ -z "$path" ] && path="$mbdisk/.Entware"


# set_env() {

# 	echo "alias opkg=/opt/bin/opkg" >> ${mbroot}/config/profile
# 	logsh "【$service】" "已修改opkg配置，请运行source /etc/profile生效！"
	
# }

# clear_env() {
# 	sed -i '/alias opkg/d' ${mbroot}/config/profile
# }

init() {

	logsh "【$service】" "初始化${appname}服务..."
	if [ -z "$path" ]; then 
		logsh "【$service】" "未配置安装路径！" 
		exit
	fi
	[ ! -d /opt/bin ] && mount -o blind "$path" /opt > /dev/null 2>&1
	result1=$(echo ${profilepath} | grep -c /opt/sbin)
	result2=$(echo ${libpath} | grep -c /opt/lib)
	[ "$result1" == '0' ] && mbdb set mixbox.main.profilepath="${profilepath}:/opt/bin:/opt/sbin"
	[ "$result2" == '0' ] && mbdb set mixbox.main.libpath="${libpath}:/opt/lib"
	
	if [ ! -f $path/etc/init.d/rc.unslung ]; then
		logsh "【$service】" "检测到第一次运行${appname}服务，正在安装..."
		mkdir -p $path > /dev/null 2>&1
		[ $? -ne 0 ] && logsh "【Tools】" "创建目录失败，检查你的路径是否正确！" && end
		umount -lf /opt > /dev/null 2>&1
		mount -o blind $path /opt
		if [ "$model" = "linux_arm" ]; then
			if [ "$(uname -r | cut -d'.' -f1)" -ge '3' ]; then
				wget -O - http://bin.entware.net/armv7sf-k3.2/installer/generic.sh | sh
			else
				wget -O - http://bin.entware.net/armv7sf-k2.6/installer/generic.sh | sh
			fi
		elif [ "$model" = "linux_mips" ]; then
			wget -O - http://bin.entware.net/mipselsf-k3.4/installer/generic.sh | sh
		elif [ "$model" = "linux_x86_64" ]; then
			wget -O - http://bin.entware.net/x64-k3.2/installer/generic.sh | sh
		else
			logsh "【Tools】" "不支持你的设备！"
			end
		fi
		if [ $? -ne 0 ]; then
			logsh "【Tools】" "【${appname}】服务安装失败"
			umount -lf /opt
			rm -rf $path
			exit 1
		fi
		/opt/bin/opkg update
		/opt/bin/opkg install curl
		source /etc/profile > /dev/null 2>&1
		logsh "【$service】" "安装完成，请运行source /etc/profile使配置生效!"
		logsh "【$service】" "如需安装ONMP，参考https://github.com/mixbox/ONMP"
	fi
	# echo >> ${mbroot}/config/profile
	#if [ -z "$(cat ${mbroot}/config/profile | grep "alias opkg")" ]; then
	#	echo "alias opkg=/opt/bin/opkg" >> ${mbroot}/config/profile
	# set_env
	#fi
}

start () {

	result=$(ps | grep "{${appname}}" | grep -v grep | wc -l)
    	if [ "$result" -gt '2' ];then
		logsh "【$service】" "${appname}已经在运行！"
		exit 1
	fi
	logsh "【$service】" "正在启动${appname}服务... "

	init
	
	# open_port
    # write_firewall_start
	# ${mbroot}/apps/${appname}/bin start >> /tmp/messages 2>&1
	logsh "【$service】" "启动依赖${appname}的所有插件..."
	mbdb keys ${appname}.app | while read line
	do
		[ "$(mbdb get ${appname}.app.${line})" != '1' ] && continue 
		mbdb set ${line}.main.enable=1
		${mbroot}/apps/${line}/scripts/${line}.sh status
		if [ "$(mbdb get mixbox.${line}.status | cut -d'|' -f2)" = '0' ]; then
			${mbroot}/apps/${line}/scripts/${line}.sh restart
		fi
	done

	logsh "【$service】" "${appname}服务启动完成"
	[ "$onmp" == '1' ] && sh -c "$(curl -kfsSl https://raw.githubusercontent.com/monlor/ONMP/master/oneclick.sh)"

}

stop () {

	logsh "【$service】" "正在停止${appname}服务... "
	[ "$enable" == '0' ] && destroy
	# ${mbroot}/apps/${appname}/bin stop >> /tmp/messages 2>&1
	[ -d /opt/bin ] && umountsh /opt
	# ps | grep ${mbroot}/apps/${appname}/bin | grep -v grep | awk '{print$1}' | xargs kill -9 > /dev/null 2>&1
	# 
	# clear_env
	logsh "【$service】" "停止成功，请运行source /etc/profile使配置生效!"
	logsh "【$service】" "若要重置【${appname}】服务，删除$path文件并启动即可"

}

destroy() {

	logsh "【$service】" "关闭依赖${appname}的所有插件..."
	local uciname=app
	mbdb keys $appname.app | while read line
	do
		[ "$(mbdb get $appname.app.${line})" != '1' ] && continue 
		${mbroot}/apps/${line}/scripts/${line}.sh stop
		# 后将enable置为0不会运行destroy方法，保存依赖entware的插件列表
		mbdb set ${line}.main.enable=0
	done
	mbdb set mixbox.main.profilepath="$(echo "$profilepath" | sed -e 's/:\/opt\/bin:\/opt\/sbin//')"
	mbdb set mixbox.main.libpath="$(echo "$libpath" | sed -e 's/:\/opt\/lib//')"

}

end() {

        mbdb set $appname.main.enable=0
        
        stop && exit 1

}


status() {

	result1=$(echo ${libpath} | grep -c "/opt/lib")
	result2=$(echo ${profilepath} | grep -c /opt/sbin)
	if [ -d $path ] && [ "$result1" != '0' ] && [ "$result2" != '0' ] && [ -d /opt/bin ]; then
		status="安装路径: $path|1"
	else
		status="未运行|0"
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
