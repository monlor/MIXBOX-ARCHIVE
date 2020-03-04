#!/bin/sh
#copyright by monlor
source /etc/mixbox/bin/base

detect_apps() {

	applist installed -n| while read line
	do
		${mbroot}/apps/${line}/scripts/${line}.sh status
		result1="$(mbdb get ${line}.main.enable)"
		result2="$(mbdb get ${line}.main.status | cut -d'|' -f2)"
		if [ "$result1" = '1' ] && [ "$result2" = '0' ]; then
			${mbroot}/apps/${line}/scripts/${line}.sh restart
		fi
	done

}

detect_update() {
	if [ "$(mbdb get mixbox.main.autoupdate)" = '1' ]; then
		mixbox get_version 1> /dev/null
		toolsver="$(applist mixbox -v)"
		if [ -z "$toolsver" ]; then
			logsh "【Tools】" "未获取到工具箱版本信息！"
		else
			if [ "$(versioncmp $mbver $toolsver)" = '1' ]; then
				logsh "【Tools】" "检测到工具箱有更新！即将更新..." && sleep 2
				mixbox update
			fi
		fi
		applist installed -n | while read line; do
			[ "$(mbdb get ${line}.main.enable)" = '0' ] && continue
			appver_online="$(cat ${mbtmp}/versions.txt | grep "${line}" | cutsh 2)"
			appver_local="$(mbdb get mixbox.${line}.version)"
			[ -z "$appver_local" -o -z "$appver_online" ] && logsh "【Tools】" "未获取插件${line}的版本信息！" && continue
			if [ "$(versioncmp $appver_local $appver_online)" = '1' ]; then
				logsh "【Tools】" "检测到插件${line}有更新！即将更新..." && sleep 2
				${mbroot}/scripts/appmanage.sh upgrade ${line}
				${mbroot}/apps/${line}/scripts/${line}.sh restart
			fi
		done
	fi
}

detect_others() {
	if [ -f "$mbdisk/uninstall_mixbox" ]; then
		logsh "【Tools】" "检测到工具箱出现问题，正在备份并卸载工具箱..."
		mixbox backup
		cp /etc/mbbackup.tar.gz $mbdisk/mbbackup.tar.gz
		mixbox uninstall || ${mbroot}/scripts/uninstall.sh
		echo "工具箱已卸载并备份了工具箱配置到这里：$mbdisk/mbbackup.tar.gz" > $mbdisk/uninstall_tools.txt
		rm -rf $mbdisk/uninstall
	fi
	if [ -f "$mbdisk/fix_dropbear" ]; then
		logsh "【Tools】" "检测到ssh出现问题，正在尝试修复..."
		killall -9 dropbear
		daemon ${mbroot}/apps/dropbear/bin/dropbear -p 3333 -d ${mbroot}/apps/dropbear/config/dropbear_dss_host_key -r ${mbroot}/apps/dropbear/config/dropbear_rsa_host_key
		# echo -e "123456/n123456" | passwd root
		echo "启动ssh服务器，登录地址：[ssh root@$lanip -p 3333]，Have Fun!" > $mbdisk/fix_dropbear.txt
		rm -rf $mbdisk/fix_dropbear
	fi
}


if [ -z "$(pssh | grep -w ${mbroot}/bin/mixbox)" ]; then
	applist update
	detect_update
	detect_apps 
	detect_others
fi


