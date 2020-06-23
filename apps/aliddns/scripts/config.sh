#!/bin/sh
#copyright by monlor

eval `mbdb export aliddns`
source "$(mbdb get mixbox.main.path)"/bin/base
echo "********* $service ***********"
echo "[${appinfo}]"
readsh "启动${appname}服务[1/0] " "enable" "1"

if [ "$enable" == '1' ]; then
  # Scripts Here
  read -p "修改${appname}配置？[1/0] " res
  if [ "$res" = '1' ]; then
    readsh "请输入${appname}访问ID" "app_key"
    readsh "请输入${appname}访问密钥" "app_secret"
    readsh "请输入${appname}域名[例如@.mixbox.com或www.mixbox.com]" "domain"
    readsh "请输入${appname}检查分钟间隔(建议10)" "time" "10"
  fi                
  readsh "启用ipv6支持[1/0]" "ipv6" "0"

  readsh "重启${appname}服务[1/0]" "res" "1"
  [ "$res" != '0' ] && exit 0
fi
exit 1