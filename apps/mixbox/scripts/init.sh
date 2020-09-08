#!/bin/sh
#copyright by monlor
source /etc/mixbox/bin/base

logsh "【Tools】" "工具箱初始化脚本启动..."
[ ! -d "${mbroot}" ] && logsh "【Tools】" "未找到工具箱文件！" && exit 1
# mount -o remount,rw /

result=`ps | grep {init.sh} | grep -v grep | wc -l`
if [ "$result" -gt '2' ]; then
        logsh "【Tools】" "检测到初始化脚本已在运行"
        exit
fi

logsh "【Tools】" "检查环境变量配置"
result=$(cat /etc/profile | grep -c mixbox/config)
if [ "$result" == 0 ]; then
	echo "source ${mbroot}/config/profile" >> /etc/profile
fi

logsh "【Tools】" "检查定时任务配置"
cru a monitor "*/10 * * * * ${mbroot}/scripts/monitor.sh"

logsh "【Tools】" "检查工具箱开机启动配置"
result=$(cat /etc/firewall.user 2> /dev/null | grep init.sh | wc -l) 
if [ "$result" == '0' ]; then
	echo "${mbroot}/scripts/init.sh" >> /etc/firewall.user
fi

logsh "【Tools】" "执行工具箱监控脚本"
${mbroot}/scripts/monitor.sh

logsh "【Tools】" "防火墙重启插件检查"
mbdb show mixbox.firewall | while read line; do
	reload="$(echo $line | cut -d'=' -f2)"
	if [ "$reload" = '1' ]; then
		appname="$(echo $line | cut -d'=' -f1)"
		${mbroot}/apps/${appname}/scripts/${appname}.sh reload
	fi
done

# logsh "【Tools】" "启动工具箱监测程序..."
# [ -z "$(pssh | grep ${mbroot}/bin/monitor)" ] && daemon ${mbroot}/bin/monitor

logsh "【Tools】" "运行用户自定义脚本"
${mbroot}/scripts/userscript.sh

