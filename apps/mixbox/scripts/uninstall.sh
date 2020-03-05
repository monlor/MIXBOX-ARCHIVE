#!/bin/sh
#copyright by monlor
[ -n "$(uci -q get monlor.tools)" ] && echo "工具箱版本过低，此卸载程序已不再支持，请执行[$(uci -q get monlor.tools.path)/scripts/uninstall.sh]卸载工具箱后重新安装新的版本！" && exit 1
source /etc/mixbox/bin/base

clear
logsh "【Tools】" "即将卸载工具箱，按任意键继续(Ctrl + C 退出)."
read answer

logsh "【Tools】" "正在卸载工具箱..."

logsh "【Tools】" "停止所有插件"

ls ${mbroot}/apps 2> /dev/null | while read line
do
	result=$(mbdb get ${line}.main.enable)
	if [ "$result" == '1' ]; then
		mbdb set mixbox.${line}.enable='0' 
		${mbroot}/apps/${line}/scripts/${line}.sh stop
	fi
done

logsh "【Tools】" "删除定时任务"
cru c 

logsh "【Tools】" "删除所有工具箱配置信息"

result=$(cat /etc/profile | grep -c mixbox/config)
if [ "$result" != 0 ]; then
	sed -i "/mixbox\/config/d" /etc/profile
fi

result=$(cat /etc/firewall.user | grep init.sh | wc -l) > /dev/null 2>&1
if [ "$result" != '0' ]; then
	sed -i "/init.sh/d" /etc/firewall.user
fi

logsh "【Tools】" "See You!"

rm -rf ${mbroot} /etc/mixbox
