#!/bin/sh 
source /etc/mixbox/bin/base
eval `mbdb export miwifi`

modify_samba() {
	[ ! -d "$samba_path" ] && mkdir -p $samba_path
	sed -i "1,/path/ s#\(path\).*#\1 = $samba_path#" /etc/samba/smb.conf
	killall smbd &> /dev/null && /usr/sbin/smbd -D &> /dev/null
	killall nmbd &> /dev/null && /usr/sbin/nmbd -D &> /dev/null
	cru a "${appname}" "*/5 * * * * ${mbroot}/apps/${appname}/scripts/miwifi_check.sh"
	samba_text="已修改"
}

recover_samba() {
	/etc/init.d/samba restart &> /dev/null &
	cru d "${appname}"
	samba_text="未修改"
}

enable_update() {
	sed -i "/otapredownload/d" /etc/crontabs/root
    echo "15 3,4,5 * * * /usr/sbin/otapredownload >/dev/null 2>&1" >> /etc/crontabs/root
	update_text="启用"
}

disable_update() {
    sed -i "/otapredownload/d" /etc/crontabs/root
	update_text="禁用"
}

enable_xunlei() {
	if [ -z "`pidof etm`" ]; then
		sed -i 's@/etc/thunder@/etc/config/thunder@g' /etc/init.d/xunlei
		if [ ! -d /etc/config/thunder ]; then
				cp -a  /etc/thunder /etc/config
				rm -rf /etc/thunder
		fi
		/etc/init.d/xunlei enable
		/etc/init.d/xunlei start &
	fi
	xunlei_text="启用"
}

disable_xunlei() {
	killall etm 2>/dev/null
	/etc/init.d/xunlei disable 2>/dev/null
	sed -i 's@/etc/config/thunder@/etc/thunder@g' /etc/init.d/xunlei
	if [ -d /etc/config/thunder ]; then
			cp -a  /etc/config/thunder /etc
			rm -rf /etc/config/thunder
	fi
	xunlei_text="禁用"
}

enable_remote_web() {
	if [ -z "$(cat /etc/sysapihttpd/miwifi-webinitrd.conf | grep mixbox)" ]; then
		cp -f /etc/sysapihttpd/miwifi-webinitrd.conf ${mbtmp}
		sed -i '/set \$finalvar \"\$canproxy \$isluci\"/i\    set \$isluci "1"; #mixbox' ${mbtmp}/miwifi-webinitrd.conf 
		mount --bind ${mbtmp}/miwifi-webinitrd.conf /etc/sysapihttpd/miwifi-webinitrd.conf
		/etc/init.d/sysapihttpd restart &> /dev/null
		remote_text="启动"
		iptables -I INPUT -p tcp --dport 8098 -j ACCEPT &> /dev/null
	fi
}

disable_remote_web() {
	umount -lf /etc/sysapihttpd/miwifi-webinitrd.conf &> /dev/null
	rm -rf ${mbtmp}/miwifi-webinitrd.conf &> /dev/null
	remote_text="禁用"
	iptables -D INPUT -p tcp --dport 8098 -j ACCEPT &> /dev/null 
}
 
start() {

    [ -n "$(pidof ${appname})" ] && logsh "【$service】" "${appname}已经在运行！" && exit 1
    logsh "【$service】" "正在启动${appname}服务... "
    # cru a "${appname}" "0 6 * * * ${mbroot}/apps/${appname}/scripts/${appname}.sh restart"
    # Scripts Here
    # open_port
    # write_firewall_start
    # daemon ${mbroot}/apps/${appname}/bin/${appname}
    if [ -n "$samba_path" ]; then
		modify_samba 
		logsh "【$service】" "系统samba服务路径修改为：$samba_path"
	else
		recover_samba
		logsh "【$service】" "系统samba服务路径修改：$samba_text"
	fi
    [ "$miwifi_noupdate" = '1' ] && disable_update || enable_update
	logsh "【$service】" "系统更新服务修改为：$update_text"
    [ "$xunlei_disable" = '1' ] && disable_xunlei || enable_xunlei
	logsh "【$service】" "系统迅雷服务修改为：$xunlei_text"
	[ "$remote_web" = '1' ] && enable_remote_web || disable_remote_web
	logsh "【$service】" "远程Web访问修复：$remote_text"
	cru a "${appname}" "*/5 * * * * ${mbroot}/apps/${appname}/scripts/miwifi_check.sh"
    # [ $? -ne 0 ] && logsh "【$service】" "启动${appname}服务失败！" && end
    logsh "【$service】" "启动${appname}服务完成！"
    status
	open_port
        
}

stop() {

    logsh "【$service】" "正在停止${appname}服务... "
	[ "$enable" = '0' ] && destroy

}

destroy() {
        
    # End app, Scripts here 
	recover_samba
	disable_update
	disable_xunlei
	disable_remote_web
    cru d "${appname}"
    return

}

end() {

    mbdb set $appname.main.enable=0
    
    stop
    exit 1

}

status() {

    if [ "$enable" = '1' ]; then
        status="已启动|1"
    else
        status="未运行|0"
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

