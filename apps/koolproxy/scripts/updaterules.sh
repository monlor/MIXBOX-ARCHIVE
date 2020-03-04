#!/bin/sh
#copyright by monlor
source /etc/mixbox/bin/base
eval `mbdb export koolproxy`

logsh "【$service】" "更新用户自定义规则"
wgetsh ${mbroot}/apps/${appname}/bin/data/rules/user.txt ${kp_rule_user}
[ $? -ne 0 ] && logsh "【$service】" "更新用户自定义规则失败"