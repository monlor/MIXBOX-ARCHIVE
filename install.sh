#!/bin/sh -e
#copyright by monlor
   
clear
logsh() {
	# 输出信息到/tmp/messages和标准输出
	logger -s -p 1 -t "$1" "$2"
	return 0
	 
} 
echo "***********************************************"
echo "**                                           **"
echo "**            Welcome to MIXBOX !            **"
echo "**                                           **"
echo "***********************************************"
logsh "【Tools】" "请按任意键安装工具箱(Ctrl + C 退出)."
read answer
#check root
# [ "$USER" != "root" ] && logsh "【Tools】"  "请使用root用户安装工具箱！" && exit 1
mburl="${MB_URL:-https://cdn.jsdelivr.net/gh/monlor/mbfiles}"
mbtmp="/tmp/mbtmp"
[ ! -d "${mbtmp}" ] && mkdir -p ${mbtmp}
model=$(uname -ms | tr ' ' '_' | tr '[A-Z]' '[a-z]')
[ -n "$(echo $model | grep -E "linux.*aarch64.*")" ] && model="linux_aarch64"
[ -n "$(echo $model | grep -E "linux.*arm.*")" ] && model="linux_arm"
[ -n "$(echo $model | grep -E "linux.*mips.*")" ] && model="linux_mips"
[ -n "$(echo $model | grep -E "linux.*x86_64.*")" ] && model="linux_x86_64"
echo "请在以下路径中选择一个合适的工具箱安装位置和一个用户文件目录："
echo "小米路由器硬盘版推荐 工具箱安装位置：/etc，用户目录：/userdisk/data"
echo "小米路由器普通版推荐 工具箱安装位置：/etc，用户目录：/extdisks/sda*"
echo "如果未插入u盘，用户目录可与工具箱安装位置相同！"
df -h | sed 1d | awk '{print NR"."$6}'
read -p "请输入你的工具箱安装路径[可手动输入路径]：" mbroot
read -p "请输入你的用户文件目录[可手动输入路径]：" mbdisk
if [ -n "$(echo "$mbroot" | grep -E "^[0-9][0-9]*$")" ]; then
	mbroot="$(df -h | sed 1d | awk '{print $6}' | sed -n "$mbroot"p)/mixbox"
else
	mbroot=${mbroot}/mixbox
fi
if [ -n "$(echo "$mbdisk" | grep -E "^[0-9][0-9]*$")" ]; then
	mbdisk="$(df -h | sed 1d | awk '{print $6}' | sed -n "$mbdisk"p)"
fi

if [ -d "${mbroot}" -o -d /etc/mixbox -o -L /etc/mixbox ]; then
	read -p "工具箱已安装，清除并继续？[1/0] " res 
	[ "$res" = '1' ] && rm -rf /etc/mixbox || exit 1
fi

logsh "【Tools】" "下载工具箱文件..."
rm -rf ${mbtmp}/mixbox.tar.gz > /dev/null 2>&1
if command -v curl &> /dev/null; then
	result=$(curl -w %{http_code} -skLo ${mbtmp}/mixbox.tar.gz ${mburl}/appstore/mixbox_${model}.tar.gz)
else
	wget-ssl -q --no-check-certificate --tries=1 --timeout=10 -O ${mbtmp}/mixbox.tar.gz ${mburl}/appstore/mixbox_${model}.tar.gz
	[ $? -eq 0 ] && result="200"
fi
[ "$result" != "200" ] && logsh "【Tools】" "文件下载失败！" && exit 1
logsh "【Tools】" "解压工具箱文件"
tar -zxvf ${mbtmp}/mixbox.tar.gz -C ${mbtmp} > /dev/null
[ $? -ne 0 ] && logsh "【Tools】" "文件解压失败！" && exit 1 
# 安装工具箱文件
cp -rf ${mbtmp}/mixbox ${mbroot}
chmod -R +x ${mbroot}/*
[ "${mbroot}" != "/etc/mixbox" ] && ln -s ${mbroot} /etc/mixbox

## for ubuntu
if uname -v | grep "Ubuntu" &> /dev/null; then
	logsh "【Tools】" "正在切换默认Shell为bash，请输入no！"
	dpkg-reconfigure dash
fi   

logsh "【Tools】" "初始化工具箱配置信息..."
mkdir ${mbroot}/mbdb
mkdir ${mbroot}/var
mkdir ${mbroot}/var/log 
mkdir ${mbroot}/var/run
touch ${mbroot}/config/applist.txt #初始化插件列表
cat ${mbroot}/config/mixbox.uci| while read line; do
    [ -z "$line" ] && continue
    ucikey="$(echo $line | cut -d'=' -f1)"
    ucivalue="$(echo $line | cut -d'=' -f2 | sed -e 's/\"//g')"
    ${mbroot}/bin/mbdb set mixbox.main."$ucikey"="$ucivalue"
done
${mbroot}/bin/mbdb set mixbox.main.mbdisk="${mbdisk}"
${mbroot}/bin/mbdb set mixbox.main.path="${mbroot}"
${mbroot}/bin/mbdb set mixbox.main.url="${mburl}"
${mbroot}/bin/mbdb set mixbox.main.model="${model}"

logsh "【Tools】" "执行工具箱初始化脚本..."
kill -9 $(echo $(ps | grep mixbox/| grep -v grep | awk '{print$1}')) > /dev/null 2>&1
${mbroot}/scripts/init.sh
rm -rf ${mbtmp}/mixbox.tar.gz
rm -rf ${mbtmp}/mixbox
logsh "【Tools】" "工具箱安装完成!"

logsh "【Tools】" "运行mixbox命令即可配置工具箱"
rm -rf ${mbtmp}/install.sh
