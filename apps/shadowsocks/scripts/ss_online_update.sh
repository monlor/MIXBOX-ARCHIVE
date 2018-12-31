#!/bin/sh
#copyright by monlor
source /etc/mixbox/bin/base 
eval `mbdb export shadowsocks`

online_config=${mbroot}/apps/${appname}/config/ssserver_online.conf
local_config=${mbroot}/apps/${appname}/config/ssserver.conf

decode_url_link(){
	link=$1
	num=$2
	len=$((${#link}-$num))
	mod4=$(($len%4))
	if [ "$mod4" -gt "0" ]; then
		var="===="
		newlink=${link}${var:$mod4}
		echo -n "$newlink" | sed 's/-/+/g; s/_/\//g' | base64 -d 2>/dev/null
	else
		echo -n "$link" | sed 's/-/+/g; s/_/\//g' | base64 -d 2>/dev/null
	fi
}

get_ss_config() {
	decode_link="$1"
	server=$(echo "$decode_link" |awk -F':' '{print $1}')
	server_port=$(echo "$decode_link" |awk -F':' '{print $2}')
	protocol=$(echo "$decode_link" |awk -F':' '{print $3}')
	encrypt_method=$(echo "$decode_link" |awk -F':' '{print $4}')
	obfs=$(echo "$decode_link" |awk -F':' '{print $5}'|sed 's/_compatible//g')
	#password=$(echo "$decode_link" |awk -F':' '{print $6}'|awk -F'/' '{print $1}')
	
	password=$(decode_url_link $(echo "$decode_link" |awk -F':' '{print $6}'|awk -F'/' '{print $1}') 0)
	
	obfsparam_temp=$(echo "$decode_link" |awk -F':' '{print $6}'|grep -Eo "obfsparam.+"|sed 's/obfsparam=//g'|awk -F'&' '{print $1}')
	[ -n "$obfsparam_temp" ] && obfsparam=$(decode_url_link $obfsparam_temp 0) || obfsparam=''
	
	protoparam_temp=$(echo "$decode_link" |awk -F':' '{print $6}'|grep -Eo "protoparam.+"|sed 's/protoparam=//g'|awk -F'&' '{print $1}')
	[ -n "$protoparam_temp" ] && protoparam=$(decode_url_link $protoparam_temp 0|sed 's/_compatible//g') || protoparam=''
	
	remarks_temp=$(echo "$decode_link" |awk -F':' '{print $6}'|grep -Eo "remarks.+"|sed 's/remarks=//g'|awk -F'&' '{print $1}')
	[ -n "$remarks_temp" ] && remarks=$(decode_url_link $remarks_temp 0 | tr "\n" " " | sed -r 's/[ ]|,|\[|\]|\*|\\|\///g') || remarks="$server"
	
	group_temp=$(echo "$decode_link" |awk -F':' '{print $6}'|grep -Eo "group.+"|sed 's/group=//g'|awk -F'&' '{print $1}')
	[ -n "$group_temp" ] && group=$(decode_url_link $group_temp 0) || group='AutoSuBGroup'
	# [ -n "$group" ] && group_base64=`echo $group | base64_encode | sed 's/ -//g'`
	# [ -n "$server" ] && server_base64=`echo $server | base64_encode | sed 's/ -//g'`	
	#把全部服务器节点写入文件 /usr/share/shadowsocks/serverconfig/all_onlineservers

}

local_update() {

	if [ -n "$ssuri" ]; then
		# 检测ss ssr
		NODE_FORMAT1=`echo $ssuri | grep -E "^ss://"`
		NODE_FORMAT2=`echo $ssuri | grep -E "^ssr://"`
		if [ -n "$NODE_FORMAT1" ];then
			logsh "【$service】" "暂不支持ss节点订阅..." && exit 1
		elif [ -n "$NODE_FORMAT2" ];then
			urllinks=$(echo $ssuri | sed 's/ssr:\/\///g')
			decode_link=$(decode_url_link $urllinks 0)
			get_ss_config $decode_link
			read -p "确定要添加节点：[$remarks,$server,$server_port,$password,$encrypt_method...][1/0]? " res
			if [ "$res" == '1' ]; then
				cat "$local_config" | grep -v "$remarks" > ${mbtmp}/server.conf
				mv -f ${mbtmp}/server.conf "$local_config"
				echo "ssr,$remarks,$server,$server_port,$password,$encrypt_method,$protocol,$obfs,$protoparam,$obfsparam" >> "$local_config"
			fi
		fi
	fi

}

online_update() {

	cat ${mbroot}/apps/${appname}/config/subscribe_link.txt | while read ssr_subscribe_link
	do
		logsh "【$service】" "更新订阅地址：$ssr_subscribe_link"
		for i in $(seq 1 6); do
			logsh "【$service】" "第$i次下载节点..."
			wgetsh ${mbtmp}/ssr_subscribe_file.txt $ssr_subscribe_link
			if [ $? -ne 0 ]; then
				logsh "【$service】" "下载订阅节点失败，1秒后重试！" 
				sleep 1
			else
				break
			fi
		done
		[ ! -f ${mbtmp}/ssr_subscribe_file.txt ] && logsh "【$service】" "下载订阅节点失败！" && exit 1
		decode_url_link `cat ${mbtmp}/ssr_subscribe_file.txt` 0 > ${mbtmp}/ssr_subscribe_file_temp1.txt
		# 检测ss ssr
		NODE_FORMAT1=`cat ${mbtmp}/ssr_subscribe_file_temp1.txt | grep -E "^ss://"`
		NODE_FORMAT2=`cat ${mbtmp}/ssr_subscribe_file_temp1.txt | grep -E "^ssr://"`
		if [ -n "$NODE_FORMAT1" ];then
			logsh "【$service】" "暂不支持ss节点订阅..." && exit 1
		elif [ -n "$NODE_FORMAT2" ];then
			maxnum=$(decode_url_link `cat ${mbtmp}/ssr_subscribe_file.txt` 0 | grep "MAX=" | awk -F"=" '{print $2}' | grep -Eo "[0-9]+")
			if [ -n "$maxnum" ]; then
				urllinks=$(decode_url_link `cat ${mbtmp}/ssr_subscribe_file.txt` 0 | sed '/MAX=/d' | shuf -n $maxnum | sed 's/ssr:\/\// /g')
			else
				urllinks=$(decode_url_link `cat ${mbtmp}/ssr_subscribe_file.txt` 0 | sed 's/ssr:\/\// /g')
			fi
			[ -z "$urllinks" ] && logsh "【$service】" "订阅节点解析失败！" && exit 1
			echo -n > $online_config
			for link in $urllinks
			do
				decode_link=$(decode_url_link $link 0)
				get_ss_config $decode_link
				logsh "【$service】" "添加${appname}订阅节点：$remarks[$server]" -s
				echo "ssr,$remarks,$server,$server_port,$password,$encrypt_method,$protocol,$obfs,$protoparam,$obfsparam" >> $online_config
			done
			logsh "【$service】" "ss订阅节点更新完成！"
			
		fi
		rm -rf ${mbtmp}/ssr_subscribe_file.txt
	done
}

if [ "$1" == "add" ]; then
	echo "URI地址添加节点..."
	action="uri" 
	ssuri="$2"
	local_update
else
	echo "在线更新ssr订阅节点..."
	online_update
fi







