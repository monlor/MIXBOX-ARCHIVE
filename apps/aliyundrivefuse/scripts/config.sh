#!/bin/sh
#copyright by monlor

eval `mbdb export aliyundrivefuse`
source "$(mbdb get mixbox.main.path)"/bin/base
echo "********* $service ***********"
echo "[${appinfo}]"
readsh "启动${appname}服务[1/0] " "enable" "1"
if [ "$enable" == '1' ]; then
  # Scripts Here
  echo "获取refresh token：https://pic.monlor.com/images/2022/04/25/5ab434eaa61647ab88576e21e96a4cc0.png"
  readsh "请输入${appname}的refresh-token" "refresh_token"
  readsh "请输入${appname}的挂载路径" "mount_path"
  if [ ! -d "${mount_path}" ]; then
    readsh "路径${mount_path}不存在！是否创建" "res" "1"
    mkdir -p "${mount_path}"
  fi
  # readsh "请输入${appname}外网访问配置[1/0]" "openport" "0"
  readsh "重启${appname}服务[1/0]" "res" "1"
  [ "$res" != '0' ] && exit 0
fi
exit 1
