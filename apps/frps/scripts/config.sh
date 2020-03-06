#!/bin/sh
#copyright by monlor

eval `mbdb export frps`
source /etc/mixbox/bin/base
uciset="mbdb set $appname.main"
echo "********* $service ***********"
echo "[${appinfo}]"
echo "技巧：回车表示默认或历史设置，-1表示还原默认或不启用"
readsh "启动${appname}服务[1/0] " "enable" "1"

if [ "$enable" == '1' ]; then
  # Scripts Here
	read -p "修改${appname}配置信息？[1/0] " res
	if [ "$res" = '1' ]; then
		readsh "请输入${appname}运行端口号" "port" "7000"
		readsh "请输入${appname}的udp端口号" "udp_port" "7001"
		readsh "请输入${appname}的kcp配置[1/0]" "kcp" "1"
		readsh "请输入${appname}用于http穿透的端口号" "http_port" "90"
		readsh "请输入${appname}用于https穿透的端口号" "https_port" "91"
		readsh "请输入${appname}访问密钥" "token" "12345678"
		readsh "请输入${appname}子域名" "subdomain" 
		read -p "是否启用${appname}的web控制面板？[1/0] " res
		[ -n "$res" ] && mbdb set $appname.main.dashboard="$res"
		if [ "$res" = '1' ]; then
			readsh "请输入${appname}控制面板端口号" "dashboard_port" "7500"
			readsh "请输入${appname}控制面板用户名" "dashboard_user" "admin"
			readsh "请输入${appname}控制面板密码" "dashboard_pwd" "admin"
		fi
	fi
	readsh "请输入${appname}外网访问配置[1/0]" "openport" "1"
	return 0
else
  return 1
fi
