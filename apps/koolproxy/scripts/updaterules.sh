#!/bin/sh
source /etc/mixbox/bin/base
eval `mbdb export koolproxy`

local_path=${mbroot}/apps/${appname}/bin/data/
rule_url="http://router.houzi-blog.top:3090"
ipset_url="https://houzi008.coding.net/p/koolproxy_list/d/koolproxy_list/git/raw/master/koolproxy_ipset.conf"
# xinggsf_url="https://raw.githubusercontent.com/xinggsf/Adblock-Plus-Rule/master/mv.txt"
# custom_url="https://raw.githubusercontent.com/jwd1208/Koolproxy/main/kpr_our_rule.txt"
# adblock_url="https://raw.githubusercontent.com/project-lede/koolproxy/main/ipsetadblock/dnsmasq.adblock"

logsh "【Koolproxy】" "下载kp规则：koolproxy.txt..."
wgetsh $local_path/rules/koolproxy.txt $rule_url/koolproxy.txt
[ $? -ne 0 ] && logsh "【Koolproxy】" "更新用户koolproxy.txt规则失败"

logsh "【Koolproxy】" "下载kp规则：daily.txt..."
wgetsh $local_path/rules/daily.txt $rule_url/daily.txt
[ $? -ne 0 ] && logsh "【Koolproxy】" "更新用户daily.txt规则失败"

logsh "【Koolproxy】" "下载kp规则：kp.dat..."
wgetsh $local_path/rules/kp.dat $rule_url/kp.dat
[ $? -ne 0 ] && logsh "【Koolproxy】" "更新用户kp.dat规则失败"

# logsh "【Koolproxy】" "更新用户自定义规则"
# wgetsh $local_path/rules/user.txt $rule_url
# [ $? -ne 0 ] && logsh "【Koolproxy】" "更新用户自定义规则失败"

# logsh "【Koolproxy】" "合并乘风视频规则"
# wgetsh $local_path/rules/mv.txt $xinggsf_url
# [ $? -ne 0 ] && logsh "【Koolproxy】" "更新乘风规则失败"
# cat $local_path/rules/mv.txt >> $local_path/rules/user.txt
# rm -f $local_path/rules/mv.txt

# logsh "【Koolproxy】" "更新dnsmasq.adblock"
# wgetsh $local_path/dnsmasq.adblock $adblock_url
# [ $? -ne 0 ] && logsh "【Koolproxy】" "更新dnsmasq.adblock失败"

logsh "【Koolproxy】" "更新koolproxy_ipset.conf"
wgetsh $local_path/koolproxy_ipset.conf $ipset_url
[ $? -ne 0 ] && logsh "【Koolproxy】" "更新koolproxy_ipset.conf失败"
