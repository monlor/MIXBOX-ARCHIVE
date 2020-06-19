#!/bin/sh
#copyright by monlor

eval `mbdb export npc`
source "$(mbdb get mixbox.main.path)"/bin/base
echo "********* $service ***********"
echo "[${appinfo}]"
readsh "启动${appname}服务[1/0] " "enable" "1"
if [ "$enable" == '1' ]; then
    # Scripts Here
    readsh "请输入npc连接命令：" "connect_cmd" 

    # readsh "请输入${appname}外网访问配置[1/0]" "openport" "0"
    readsh "重启${appname}服务[1/0] " "res" "1"
    [ "$res" != '0' ] && exit 0
fi
exit 1