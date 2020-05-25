#!/bin/sh
#copyright by monlor
source /etc/mixbox/bin/base

logsh "【Tools】" "正在更新工具箱程序... "
rm -rf ${mbtmp}/mixbox.tar.gz
rm -rf ${mbtmp}/mixbox
wgetsh "${mbtmp}/mixbox.tar.gz" "$mburl/appstore/mixbox_${model}.tar.gz" > /dev/null 2>&1
[ $? -ne 0 ] && logsh "【Tools】" "工具箱文件下载失败！"  && exit

logsh "【Tools】" "解压工具箱文件"
tar -zxvf ${mbtmp}/mixbox.tar.gz -C ${mbtmp} > /dev/null 2>&1
[ $? -ne 0 ] && logsh "【Tools】" "文件解压失败！" && exit

logsh "【Tools】" "初始化uci配置信息..."
echo >> ${mbtmp}/mixbox/config/mixbox.uci # 防止最后一行读取不到
source ${mbtmp}/mixbox/config/mixbox.uci
cat ${mbtmp}/mixbox/config/mixbox.uci | while read line; do
    [ -z "$line" ] && continue
    ucikey="$(echo $line | cut -d'=' -f1)"
    ucivalue="$(echo $line | cut -d'=' -f2 | sed -e 's/\"//g')"
    mbdb set mixbox.main."$ucikey"="$ucivalue"
done
rm -rf ${mbtmp}/mixbox/scripts/userscript.sh
cp -rf ${mbtmp}/mixbox/* ${mbroot}/

logsh "【Tools】" "赋予可执行权限"
chmod -R +x ${mbroot}/bin
chmod -R +x ${mbroot}/scripts

logsh "【Tools】" "强制更新软件源"
${mbroot}/bin/mbdb set mixbox.main.url=https://monlor.coding.net/p/mbfiles/d/mbfiles/git/lfs/master

# 清理工作
logsh "【Tools】" "一点点清理工作..."
rm -rf ${mbroot}/bin/base64*

if [ -z "$(mbdb get mixbox.main.model)" ]; then
	model=$(uname -ms | tr ' ' '_' | tr '[A-Z]' '[a-z]')
	[ -n "$(echo $model | grep -E "linux.*arm.*")" ] && model="linux_arm"
	[ -n "$(echo $model | grep -E "linux.*mips.*")" ] && model="linux_mips"
	mbdb set mixbox.main.model="$model"
fi

logsh "【Tools】" "工具箱更新完成！"
if [ -n "${newinfo}" ]; then
	echo -e "-----------------------------------------"
	echo -e "${newinfo}"
	echo -e "-----------------------------------------"
fi

#删除临时文件
rm -rf ${mbtmp}/mixbox.tar.gz
rm -rf ${mbtmp}/mixbox