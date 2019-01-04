#!/bin/sh 
source /etc/mixbox/bin/base
eval `mbdb export vsftpd`

port=21
FTPUSER=${mbroot}/apps/vsftpd/config/ftpuser.conf
# binname="${appname} ${appname}-ext"

add(){
	sed -i "/$1/"d /etc/passwd
	sed -i "/$1/"d /etc/shadow
	#if [ "$4" == '0' ]; then
	sshlogin=/bin/false;
	#else
	#	sshlogin=/bin/ash;
	#fi
	if [ ! -d "$3" ]; then 
		mkdir -p $3
	fi 
	echo "$1:*:10086:10086:$1:$3:$sshlogin" >> /etc/passwd
	echo "$1:*:0:0:99999:7:::" >> /etc/shadow
	echo -e "$2\n$2" | passwd $1 > /dev/null 2>&1

}
del(){
	sed -i "/^$1/"d /etc/passwd
	sed -i "/^$1/"d /etc/shadow
	sed -i "/^$1/"d /etc/vsftpd.users &> /dev/null
}

# init_mount() {
# 	[ ! -f "${mbroot}/apps/${appname}/config/passwd" ] && cp -rf /etc/passwd ${mbroot}/apps/${appname}/config/passwd
# 	[ ! -f "${mbroot}/apps/${appname}/config/shadow" ] && cp -rf /etc/shadow ${mbroot}/apps/${appname}/config/shadow
# 	umountsh /etc/passwd 
# 	umountsh /etc/shadow
# 	mount --bind ${mbroot}/apps/${appname}/config/passwd /etc/passwd 
# 	mount --bind ${mbroot}/apps/${appname}/config/shadow /etc/shadow
# }

set_config() {

	logsh "【$service】" "加载${appname}设置... "
	[ ! -f $FTPUSER ] && logsh "【$service】" "未配置ftp用户！" && exit
	cat /etc/vsftpd.users 2> /dev/null | while read line
	do
		[ ! -z "${line}" ] && del ${line}
	done
	cat $FTPUSER | while read line
	do
		username=`cutsh ${line} 1`
		passwd=`cutsh ${line} 2`
		ftppath=`cutsh ${line} 3`
		echo $username >> /etc/vsftpd.users
		[ ! -z $username ] && add $username $passwd $ftppath
	done

	if [ `mbdb get ${appname}.main.anon_enable` = "1" ]; then
		anon_enable=YES
		anon_root=`mbdb get ${appname}.main.anon_root` || anon_root=/var/ftp 
		[ ! -d $anon_root ] && mkdir -p $anon_root
		[ ! -d $anon_root/Share ] && mkdir -p $anon_root/Share
		chmod 755 $anon_root
		dirmod=$(ls -ld $anon_root | cut -d' ' -f1)
		[ "$dirmod" == "drwxrwxrwx" ] && logsh "【$service】" "匿名访问开启失败，此目录不支持！"
		chmod 777 $anon_root/Share
		del ftp && add ftp 123 $anon_root
	else
		anon_enable=NO
	fi
	port=`mbdb get ${appname}.main.ftp_port` || port=21
	cp -rf ${mbroot}/apps/${appname}/config/${appname}.conf /etc/vsftpd.conf
	[ ! -d /var/run/vsftpd ] && mkdir -p /var/run/vsftpd
	echo -e "anonymous_enable=$anon_enable\nanon_root=$anon_root\nlisten_port=${port}" >> /etc/vsftpd.conf

}

start () {

	result=$(ps | grep ${mbroot}/apps/${appname}/bin/${appname} | grep -v grep | wc -l)
    	if [ "$result" != '0' ];then
		logsh "【$service】" "${appname}已经在运行！"
		exit 1
	fi
	logsh "【$service】" "正在启动${appname}服务... "
	# if [ ! -f ${mbroot}/apps/${appname}/bin/${appname} ]; then
	# 	bincheck ${binname} 
 #    	if [ $? -eq 0 ]; then
 #    		logsh "【$service】" "安装程序成功，链接程序到工具箱..."
 #    		ln -sf $(which $binname) ${mbroot}/apps/${appname}/bin/${appname} 
 #    	else
 #    		logsh "【$service】" "程序安装失败！"
 #    		end
 #    	fi
	# fi
	# init_mount
	set_config
	
	open_port
    write_firewall_start
	daemon ${mbroot}/apps/${appname}/bin/${appname} 
	if [ $? -ne 0 ]; then
            logsh "【$service】" "启动${appname}服务失败！"
    else
            logsh "【$service】" "启动${appname}服务完成！"
    fi

}

stop () {

	logsh "【$service】" "正在停止${appname}服务... "
	close_port
	remove_firewall_start
	# 删除用户
	cat /etc/vsftpd.users 2> /dev/null | while read line
	do
		[ ! -z "${line}" ] && del ${line}
	done
	rm -rf /etc/vsftpd.conf
	killall -9 ${appname} &> /dev/null
	

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
