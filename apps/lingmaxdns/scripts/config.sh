#!/bin/sh
#copyright by monlor

eval `mbdb export lingmaxdns`
source "$(mbdb get mixbox.main.path)"/bin/base
echo "********* $service ***********"
echo "[${appinfo}]"
readsh "启动${appname}服务[1/0] " "enable" "1"
if [ "$enable" == '1' ]; then
  # Scripts Here
  echo "插件介绍：https://www.right.com.cn/forum/thread-8137820-1-1.html"
  # readsh "请输入${appname}外网访问配置[1/0]" "openport" "0"
  readsh "重启${appname}服务[1/0]" "res" "1"
  [ "$res" != '0' ] && exit 0
fi
exit 1
