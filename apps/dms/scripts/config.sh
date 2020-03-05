#!/bin/sh

eval `mbdb export dms`
source "$(mbdb get mixbox.main.path)"/bin/base
echo "********* $service ***********"
echo "[${appinfo}]"
readsh "启动${appname}服务[1/0] " "enable" "1"
if [ "$enable" == '1' ]; then
    # Scripts Here
    readsh "请输入${appname}媒体目录" "path" "${mbdisk}"
    readsh "请输入${appname}媒体服务器名称" "servername" "mixbox-dms"
    # readsh "请输入${appname}外网访问配置[1/0]" "openport" "0"
    readsh "重启${appname}服务[1/0] " "res" "1"
    [ "$res" = '1' -o -z "$res" ] && return 1
else
    return 0
fi