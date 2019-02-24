#!/bin/sh
source /etc/mixbox/bin/base
eval `mbdb export shadowsocks`

ss_id="$1"
v2ray_config="${mbroot}/apps/${appname}/config/v2ray.json"
idinfo="$(cat ${mbroot}/apps/${appname}/config/ssserver.conf | grep ",$1," | head -1)"
[ -z "$idinfo" ] && logsh "【$service】" "未找到v2ray节点：$ss_id" && exit
ss_server=`cutsh "$idinfo" 3`
ss_port=`cutsh "$idinfo" 4`
ss_method=`cutsh "$idinfo" 5`
ss_uuid=`cutsh "$idinfo" 6`
ss_alterid=`cutsh "$idinfo"o 7`
ss_network=`cutsh "$idinfo" 8`
ss_headtype_tcp=`cutsh "$idinfo" 9`
ss_headtype_kcp=`cutsh "$idinfo" 10`
ss_network_host=`cutsh "$idinfo" 11`
ss_network_path=`cutsh "$idinfo" 12`
ss_network_security=`cutsh "$idinfo" 13`
ss_mux_enable=`cutsh "$idinfo" 14`
ss_mux_concurrency=`cutsh "$idinfo" 15`

rm -rf "$v2ray_config"
logsh "【$service】" "生成V2Ray配置文件..."
local kcp="null"
local tcp="null"
local ws="null"
local h2="null"
local tls="null"

if [ "$ss_network" != "ws" ]; then
	IFIP=`echo $ss_server | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
	if [ -z "$IFIP" ]; then
		ss_server_tmp=`nslookup $ss_server | sed 1,2d | grep -Eo "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -1` 
		[ -z "$ss_server_tmp" ] && logsh "【$service】" "v2ray服务器地址解析失败，跳过解析！" || ss_server="$ss_server_tmp"
	fi
fi

get_ws_header() {
	if [ -n "$1" ];then
		echo {\"Host\": \"$1\"}
	else
		echo "null"
	fi
}

get_h2_host() {
	if [ -n "$1" ];then
		echo [\"$1\"]
	else
		echo "null"
	fi
}

get_path(){
	if [ -n "$1" ];then
		echo \"$1\"
	else
		echo "null"
	fi
}

# tcp和kcp下tlsSettings为null，ws和h2下tlsSettings
[ -z "$ss_mux_enable" ] && local ss_mux_enable=true
[ -z "$ss_mux_concurrency" ] && local ss_mux_concurrency=8
[ "$ss_network_security" == "none" ] && ss_network_security=""
#if [ "$ss_network" == "ws" -o "$ss_network" == "h2" ];then
case "$ss_network_security" in
	tls)
		local tls="{
		\"allowInsecure\": true,
		\"serverName\": null
		}"
	;;
	*)
		local tls="null"
	;;
esac
#fi
# incase multi-domain input
if [ "`echo $ss_network_host | grep ","`" ];then
	ss_network_host=`echo $ss_network_host | sed 's/,/", "/g'`
fi

case "$ss_network" in
	tcp)
		if [ "$ss_headtype_tcp" == "http" ];then
			local tcp="{
			\"connectionReuse\": true,
			\"header\": {
			\"type\": \"http\",
			\"request\": {
			\"version\": \"1.1\",
			\"method\": \"GET\",
			\"path\": [\"/\"],
			\"headers\": {
			\"Host\": [\"$ss_network_host\"],
			\"User-Agent\": [\"Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.75 Safari/537.36\",\"Mozilla/5.0 (iPhone; CPU iPhone OS 10_0_2 like Mac OS X) AppleWebKit/601.1 (KHTML, like Gecko) CriOS/53.0.2785.109 Mobile/14A456 Safari/601.1.46\"],
			\"Accept-Encoding\": [\"gzip, deflate\"],
			\"Connection\": [\"keep-alive\"],
			\"Pragma\": \"no-cache\"
			}
			},
			\"response\": {
			\"version\": \"1.1\",
			\"status\": \"200\",
			\"reason\": \"OK\",
			\"headers\": {
			\"Content-Type\": [\"application/octet-stream\",\"video/mpeg\"],
			\"Transfer-Encoding\": [\"chunked\"],
			\"Connection\": [\"keep-alive\"],
			\"Pragma\": \"no-cache\"
			}
			}
			}
			}"
		else
			local tcp="null"
		fi        
	;;
	kcp)
		local kcp="{
		\"mtu\": 1350,
		\"tti\": 50,
		\"uplinkCapacity\": 12,
		\"downlinkCapacity\": 100,
		\"congestion\": false,
		\"readBufferSize\": 2,
		\"writeBufferSize\": 2,
		\"header\": {
		\"type\": \"$ss_headtype_kcp\",
		\"request\": null,
		\"response\": null
		}
		}"
	;;
	ws)
		local ws="{
		\"connectionReuse\": true,
		\"path\": $(get_path $ss_network_path),
		\"headers\": $(get_ws_header $ss_network_host)
		}"
	;;
	h2)
		local h2="{
	\"path\": $(get_path $ss_network_path),
	\"host\": $(get_h2_host $ss_network_host)
	}"
	;;
esac
cat > "$v2ray_config" <<-EOF
	{
		"log": {
			"access": "/dev/null",
			"error": "${mbtmp}/v2ray_log.log",
			"loglevel": "error"
		},
EOF

# logsh "【$service】"  配置v2ray dns，用于dns解析...
# cat >> "$v2ray_config" <<-EOF
# 	"inbound": {
# 	"protocol": "dokodemo-door",
# 	"port": 15353,
# 	"settings": {
# 		"address": "8.8.8.8",
# 		"port": 53,
# 		"network": "udp",
# 		"timeout": 0,
# 		"followRedirect": false
# 		}
# 	},
# EOF

cat >> "$v2ray_config" <<-EOF
	"inbound": {
		"port": 1082,
		"listen": "0.0.0.0",
		"protocol": "socks",
		"settings": {
			"auth": "noauth",
			"udp": true,
			"ip": "127.0.0.1",
			"clients": null
		},
		"streamSettings": null
	},
EOF

cat >> "$v2ray_config" <<-EOF
		"inboundDetour": [
			{
				"listen": "0.0.0.0",
				"port": 1081,
				"protocol": "dokodemo-door",
				"settings": {
					"network": "tcp,udp",
					"followRedirect": true
				}
			}
		],
		"outbound": {
			"tag": "agentout",
			"protocol": "vmess",
			"settings": {
				"vnext": [
					{
						"address": "$ss_server",
						"port": $ss_port,
						"users": [
							{
								"id": "$ss_uuid",
								"alterId": $ss_alterid,
								"security": "$ss_method"
							}
						]
					}
				],
				"servers": null
			},
			"streamSettings": {
				"network": "$ss_network",
				"security": "$ss_network_security",
				"tlsSettings": $tls,
				"tcpSettings": $tcp,
				"kcpSettings": $kcp,
				"wsSettings": $ws,
				"httpSettings": $h2
			},
			"mux": {
				"enabled": $ss_mux_enable,
				"concurrency": $ss_mux_concurrency
			}
		}
	}
EOF
