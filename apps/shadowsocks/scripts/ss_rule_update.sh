#!/bin/sh
#copyright by monlor
source /etc/mixbox/bin/base
eval `mbdb export shadowsocks`

chnroute=${mbroot}/apps/${appname}/config/chnroute.txt
gfwlist=${mbroot}/apps/${appname}/config/gfwlist.conf
cdnlist=${mbroot}/apps/${appname}/config/cdn.txt
url="https://raw.githubusercontent.com/hq450/fancyss/master/rules"

logsh "【$service】" "更新${appname}分流规则"
wgetsh $gfwlist $url/gfwlist.conf
[ $? -ne 0 ] && logsh "【$service】" "更新gfw黑名单规则失败"
wgetsh $chnroute $url/chnroute.txt
[ $? -ne 0 ] && logsh "【$service】" "更新大陆白名单规则失败"
wgetsh $cdnlist $url/cdn.txt
[ $? -ne 0 ] && logsh "【$service】" "更新cdn加速列表失败"

