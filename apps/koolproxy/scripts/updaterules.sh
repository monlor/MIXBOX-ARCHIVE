#!/bin/sh
#copyright by monlor
source /etc/mixbox/bin/base
eval `mbdb export koolproxy`
adurl="https://raw.githubusercontent.com/kysdm/ad-rules/master/user-rules-koolproxy.txt"

logsh "【$service】" "更新用户自定义规则"
wgetsh ${mbroot}/apps/${appname}/bin/data/rules/user.txt $adurl
[ $? -ne 0 ] && logsh "【$service】" "更新用户自定义规则失败"