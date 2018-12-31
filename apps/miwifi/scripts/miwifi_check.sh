#!/bin/sh 
source /etc/mixbox/bin/base
eval `mbdb export miwifi`

#检查samba共享目录
samba_path=$(mbdb get miwifi.main.samba_path)
if [ ! -z "$samba_path" ]; then
	logsh "【$service】" "检查samba共享目录配置" 
	if [ ! -f /etc/samba/smb.conf ]; then
		logsh "【$service】" "未找到samba配置文件！" 
	else
		result=$(cat /etc/samba/smb.conf | grep path | head -1 | awk '{print$3}')
		if [ "$result" != "$samba_path" ]; then
			logsh "【$service】" "检测到samba路径变更, 正在设置..."
			sed -i "1,/path/ s#\(path\).*#\1 = $samba_path#" /etc/samba/smb.conf
			killall smbd && /usr/sbin/smbd -D &> /dev/null
			killall nmbd && /usr/sbin/nmbd -D &> /dev/null
		fi
	fi
fi

if [ -z "$(cat /etc/sysapihttpd/miwifi-webinitrd.conf | grep mixbox)" ]; then
	logsh "【$service】" "远程web访问修复中..."
	umountsh /etc/sysapihttpd/miwifi-webinitrd.conf
	cp -f /etc/sysapihttpd/miwifi-webinitrd.conf ${mbtmp}
	sed -i '/set \$finalvar \"\$canproxy \$isluci\"/i\    set \$isluci "1"; #mixbox' ${mbtmp}/miwifi-webinitrd.conf 
	mount --bind ${mbtmp}/miwifi-webinitrd.conf /etc/sysapihttpd/miwifi-webinitrd.conf
	/etc/init.d/sysapihttpd restart &> /dev/null
fi