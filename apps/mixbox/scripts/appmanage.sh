#!/bin/sh
#copyright by monlor
source /etc/mixbox/bin/base
appname="$2"
[ -z "${appname}" ] && logsh "【Tools】" "请输入插件名！" && exit 1

get_app_byurl () {
	logsh "【Tools】" "下载插件安装文件..."
	wgetsh "${mbtmp}/${appname}.tar.gz" "$mburl/appstore/${appname}_${model}.tar.gz"
	if [ $? -eq 1 ]; then
		logsh "【Tools】" "文件下载失败！"
		exit
	fi
	logsh "【Tools】" "解压安装文件..."
	tar -zxvf ${mbtmp}/${appname}.tar.gz -C ${mbtmp} > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		logsh "【Tools】" "文件解压失败！" 
		exit
	fi
	logsh "【Tools】" "赋予可执行文件..."
	chmod +x -R ${mbtmp}/${appname}/
}

install () {

	logsh "【Tools】" "开始安装【${appname}】插件..."
	get_app_byurl

	# if [ "$model" = "armv7l" ]; then
	# 	rm -rf ${mbtmp}/${appname}/bin/*_mips
	# else
	# 	rm -rf ${mbtmp}/${appname}/bin/*_armv7l
	# fi
	# ls ${mbtmp}/${appname}/bin/ 2> /dev/null | while read line; do
	# 	[ -d ${mbtmp}/${appname}/bin/${line} ] && continue
	# 	mv ${mbtmp}/${appname}/bin/${line} ${mbtmp}/${appname}/bin/"$(echo ${line} | sed -e 's/_.*//g')"
	# done
	# 开始判断
	. ${mbtmp}/${appname}/config/${appname}.uci
	if [ -n "$(echo $supports | grep "$model")" ]; then
		logsh "【Tools】" "处理器架构符合安装要求"
	else
		logsh "【Tools】" "设备架构：$model，插件支持：$supports，无法安装！"
		rm -rf ${mbtmp}/${appname}
		rm -rf ${mbtmp}/${appname}.tar.gz
		exit 1
	fi

	logsh "【Tools】" "检查工具箱版本..."
	if [ "$(versioncmp $needver $mbver)" = '-1' ]; then
		logsh "【Tools】" "工具箱版本过低！【${appname}】要求工具箱版本：$needver"
		logsh "【Tools】" "插件【${appname}】安装失败！清理文件..."
		rm -rf ${mbtmp}/${appname}
		rm -rf ${mbtmp}/${appname}.tar.gz
		exit 1
	else
		logsh "【Tools】" "工具箱版本[$mbver]满足安装要求"
	fi
	logsh "【Tools】" "检查插件的额外安装脚本..."
	if [ -f ${mbtmp}/${appname}/scripts/install.sh ]; then
		logsh "【Tools】" "运行插件安装脚本"
		${mbtmp}/${appname}/scripts/install.sh
		rm -rf ${mbtmp}/${appname}/scripts/install.sh
	fi

	logsh "【Tools】" "初始化uci配置信息..."
	echo >> ${mbtmp}/${appname}/config/${appname}.uci # 防止最后一行读取不到
	cat ${mbtmp}/${appname}/config/${appname}.uci | while read line; do
        [ -z "$line" ] && continue
        local ucikey="$(echo $line | cut -d'=' -f1)"
        local ucivalue="$(echo $line | cut -d'=' -f2 | sed -e 's/\"//g')"
        mbdb set $appname.main."$ucikey"="$ucivalue"
    done
	[ "$app_enabled" = '1' ] && mbdb set ${appname}.main.enable='1' 

	logsh "【Tools】" "添加插件到工具箱..."
	sed -i "/^${appname}/d" ${mbroot}/config/applist.txt
	echo "${appname}|${appinfo}" >> ${mbroot}/config/applist.txt
	mkdir -p ${mbroot}/apps/${appname}
	cp -rf ${mbtmp}/${appname}/ ${mbroot}/apps/

	#清除临时文件
	rm -rf ${mbtmp}/${appname}
	rm -rf ${mbtmp}/${appname}.tar.gz

	logsh "【Tools】" "插件安装完成！"
	if [ -n "${newinfo}" ]; then
		echo -e "-----------------------------------------"
		echo -e "${newinfo}"
		echo -e "-----------------------------------------"
	fi

}

upgrade() {
	
	logsh "【Tools】" "开始更新【${appname}】插件..."
	!(checkuci ${appname}) && logsh "【Tools】" "插件【${appname}】未安装！" && exit 1 
	logsh "【Tools】" "先停止【${appname}】插件..."
	app_enabled="$(mbdb get ${appname}.main.enable)"
	mbdb set ${appname}.main.enable=0
	${mbroot}/apps/${appname}/scripts/${appname}.sh stop 
	install ${appname}

}

uninstall() {

	logsh "【Tools】" "开始卸载【${appname}】插件..."
	!(checkuci ${appname}) && logsh "【Tools】" "插件【${appname}】未安装！" && exit 1 	
	logsh "【Tools】" "先停止【${appname}】插件..."
	${mbroot}/apps/${appname}/scripts/${appname}.sh stop &> /dev/null
	#删除插件的配置
	logsh "【Tools】" "清除插件uci配置信息"
	mbdb clear ${appname}.*
	# 清除插件列表中的插件信息
	logsh "【Tools】" "从插件列表中移除..."
	sed -i "/^${appname}/d" ${mbroot}/config/applist.txt
	# 删除插件文件
	logsh "【Tools】" "清除所有插件文件"
	rm -rf ${mbroot}/apps/${appname} > /dev/null 2>&1
    logsh "【Tools】" "插件【${appname}】卸载完成"

}
 

case "$1" in
	install) install;;
	upgrade) upgrade ;;
	uninstall) uninstall ;;
	*) echo "Usage: $0 {add|upgrade|del} appname"
esac
