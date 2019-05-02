#!/bin/sh 
source /etc/mixbox/bin/base
eval `mbdb export shadowsocks`

[ -z "$CDN" ] && CDN=223.5.5.5
[ -z "$DNS_SERVER" ] && DNS_SERVER=8.8.8.8
[ -z "$DNS_SERVER_PORT" ] && DNS_SERVER_PORT=53
[ -z "$ss_proxy_default_mode" ] && ss_proxy_default_mode=1
[ -z "$ss_game_default_mode" ] && ss_game_default_mode=0
[ -z "$dns_red_ip" ] && dns_red_ip="$lanip"
[ "$ssgena" != "1" ] && unset ssg_mode

get_v2ray_bin() {
    result1=$(curl -skL $mburl/appsbin/v2ray-bin/$model/lastest.txt) &> /dev/null
    result2=$(${mbroot}/apps/${appname}/bin/v2ray -version | head -1 | cut -d' ' -f2) &> /dev/null
    [ -z "$result1" ] && logsh "【$service】" "获取v2ray在线版本失败，请检查网络！" && exit 1
    logsh "【$service】" "检测v2ray版本，本地版本：$result2，在线版本：$result1"
    if [ "$result1" != "$result2" ]; then
        logsh "【$service】" "版本不一致，正在更新..."
        wgetsh ${mbroot}/apps/${appname}/bin/v2ray $mburl/appsbin/v2ray-bin/$model/v2ray
        wgetsh ${mbroot}/apps/${appname}/bin/v2ctl $mburl/appsbin/v2ray-bin/$model/v2ctl
        chmod +x ${mbroot}/apps/${appname}/bin/v2ray
        chmod +x ${mbroot}/apps/${appname}/bin/v2ctl
    fi
}

get_config() {
    
    logsh "【$service】" "创建节点配置文件..."
    [ -z "$id" ] && logsh "【$service】" "未配置运行节点！" && exit
    local_ip=0.0.0.0
    [ -z "$id" ] && logsh "【$service】" "未配置运行节点！" && exit 1
    idinfo=`cat ${mbroot}/apps/${appname}/config/ssserver* | grep ",$id," | head -1`
    [ -z "$idinfo" ] && logsh "【$service】" "未找到配置节点：$id" && exit
    proxy_type=`cutsh "$idinfo" 1`
    ss_name=`cutsh "$idinfo" 2`
    ss_server=`cutsh "$idinfo" 3`
    IFIP=`echo $ss_server | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
    if [ -z "$IFIP" ]; then
        ss_server_tmp=`nslookup $ss_server | sed 1,2d | grep -Eo "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -1`
        [ -z "$ss_server_tmp" ] && logsh "【$service】" "服务器地址解析失败，跳过解析！" || ss_server="$ss_server_tmp"
    fi
    if [ "$proxy_type" = "v2ray" ]; then
        get_v2ray_bin
        ${mbroot}/apps/${appname}/scripts/general_v2ray_config.sh "$id" 
    else
        ss_server_port=`cutsh "$idinfo" 4`
        ss_password=`cutsh "$idinfo" 5`
        ss_method=`cutsh "$idinfo" 6`
        ssr_protocol=`cutsh "$idinfo" 7`
        ssr_obfs=`cutsh "$idinfo" 8`
        ssr_protocol_param=`cutsh "$idinfo" 9`
        ssr_obfs_param=`cutsh "$idinfo" 10`
        # 如果kcp成功启动，应该把ss服务端指向kcp服务端口
        if [ "$kcp_started" = 1 ]; then
            ss_server=127.0.0.1
            ss_server_port=11183
        fi
        #生成配置文件
        if [ "$proxy_type" = "ss" ]; then
            APPPATH=${mbroot}/apps/${appname}/bin/ss-redir
            LOCALPATH=${mbroot}/apps/${appname}/bin/ss-local
            cat > ${mbroot}/apps/${appname}/config/ss.conf <<-EOF
		{
		    "server": "$ss_server",
		    "server_port": $ss_server_port,
		    "local_address": "0.0.0.0",
		    "local_port": 1081,
		    "password": "$ss_password",
		    "timeout": 600,
		    "method": "$ss_method"
		}
		EOF
        else
            APPPATH=${mbroot}/apps/${appname}/bin/ssr-redir
            LOCALPATH=${mbroot}/apps/${appname}/bin/ssr-local
            cat > ${mbroot}/apps/${appname}/config/ss.conf <<-EOF
		{
		    "server": "$ss_server",
		    "server_port": $ss_server_port,
		    "local_address": "0.0.0.0",
		    "local_port": 1081,
		    "password": "$ss_password",
		    "timeout": 600,
		    "protocol": "$ssr_protocol",
		    "protocol_param": "$ssr_protocol_param",
		    "obfs": "$ssr_obfs",
		    "obfs_param": "$ssr_obfs_param",
		    "method": "$ss_method"
		}
		EOF
        fi
        cp ${mbroot}/apps/${appname}/config/ss.conf ${mbroot}/apps/${appname}/config/dns2socks.conf && sed -i 's/1081/1082/g' ${mbroot}/apps/${appname}/config/dns2socks.conf
    fi

    if [ "$ssgena" == '1' ]; then
        [ -z "$ssgid" ] && logsh "【$service】" "未配置游戏运行节点！" && exit
        idinfo=`cat ${mbroot}/apps/${appname}/config/ssserver* | grep ",$ssgid," | head -1`
        [ -z "$idinfo" ] && logsh "【$service】" "未找到配置节点：$ssgid" && exit
        proxy_type_game=`cutsh "$idinfo" 1`
        ssg_name=`cutsh "$idinfo" 2`
        ssg_server=`cutsh "$idinfo" 3`
        if [ "$proxy_type" = "v2ray" -a "$proxy_type_game" != "v2ray" -a "$ssg_server" != "$ss_server" ]; then
            logsh "【$service】" "当主进程为v2ray代理时，游戏进程只能选择同样的v2ray节点！"
            return
            ssgena=0
        fi
        if [ "$proxy_type" != "v2ray" -a "$proxy_type_game" = "v2ray" ]; then
            logsh "【$service】" "只有当主进程为v2ray代理时，游戏进程才能启用v2ray！"
            return
            ssgena=0
        fi
        [ "$proxy_type_game" = "v2ray" -o "$ssgid" == "$id" ] && return
        ssg_server_port=`cutsh "$idinfo" 4`
        ssg_password=`cutsh "$idinfo" 5`
        ssg_method=`cutsh "$idinfo" 6`
        ssg_protocol=`cutsh "$idinfo" 7`
        ssg_obfs=`cutsh "$idinfo" 8`
        ssg_protocol_param=`cutsh "$idinfo" 9`
        ssg_obfs_param=`cutsh "$idinfo" 10`
        IFIP=`echo $ssg_server | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
        if [ -z "$IFIP" ]; then
            ssg_server_tmp=`resolveip $ssg_server | head -1` 
            [ $? -ne 0 ] && logsh "【$service】" "游戏服务器地址解析失败，跳过解析！" || ssg_server="$ssg_server_tmp"
        fi
        if [ "$proxy_type_game" = "ss" ]; then
            cp -rf ${mbroot}/apps/${appname}/bin/ss-redir ${mbroot}/apps/${appname}/bin/ssg-redir
            cat > ${mbroot}/apps/${appname}/config/ssg.conf <<-EOF
		{
		    "server": "$ssg_server",
		    "server_port": $ssg_server_port,
		    "local_address": "0.0.0.0",
		    "local_port": 1085,
		    "password": "$ssg_password",
		    "timeout": 600,
		    "method": "$ssg_method"
		}
		EOF
        else
            cp -rf ${mbroot}/apps/${appname}/bin/ssr-redir ${mbroot}/apps/${appname}/bin/ssg-redir
            cat > ${mbroot}/apps/${appname}/config/ssg.conf <<-EOF
		{
		    "server": "$ssg_server",
		    "server_port": $ssg_server_port,
		    "local_address": "0.0.0.0",
		    "local_port": 1085,
		    "password": "$ssg_password",
		    "timeout": 600,
		    "protocol": "$ssg_protocol",
		    "protocol_param": "$ssg_protocol_param",
		    "obfs": "$ssg_obfs",
		    "obfs_param": "$ssg_obfs_param",
		    "method": "$ssg_method"
		}
		EOF
        fi
    fi
    # 保存代理类型
    mbdb set ${appname}.main.proxy_type="$proxy_type"

}

dnsconfig() {

    killall ss-local &> /dev/null
    killall dns2socks > /dev/null 2>&1
    if [ "$proxy_type" != "v2ray" ]; then
        logsh "【$service】" "启动ss-local本地socks5代理..."
        daemon $LOCALPATH -c ${mbroot}/apps/${appname}/config/dns2socks.conf
    fi
    logsh "【$service】" "开启dns2socks进程..."
    daemon ${mbroot}/apps/${appname}/bin/dns2socks 127.0.0.1:1082 $DNS_SERVER:$DNS_SERVER_PORT 127.0.0.1:15353 
    if [ $? -ne 0 ]; then
            logsh "【$service】" "启动失败！"
            exit
    fi
    if [ "$dns_red_enable" == '1' ]; then
        logsh "【$service】" "启用DNS重定向到$dns_red_ip"
        iptables -t nat -I PREROUTING -s $lanip/24 -p udp --dport 53 -m comment --comment "${appname}"-dns -j DNAT --to $dns_red_ip &> /dev/null
    fi
     
}

get_mode_name() {
    case "$1" in
        0)
            echo "不走代理"
        ;;
        1)
            echo "科学上网"
        ;;
    esac
}

get_game_mode() {
    case "$1" in
        0)
            echo "不走游戏"
        ;;
        1)
            echo "游戏加速"
        ;;
    esac
}

get_jump_mode(){
    case "$1" in
        0)
            echo "-j"
        ;;
        *)
            echo "-g"
        ;;
    esac
}

get_action_chain() {
    case "$1" in
        0)
            echo "RETURN"
        ;;
        1)
            echo "SHADOWSOCK"
        ;;
    esac
}

ipset_rules_smartdns() {
    # ipset deal
    logsh "【$service】" "创建ipset规则..."
    [ ! -f ${mbroot}/apps/${appname}/config/customize_black.conf ] && touch ${mbroot}/apps/${appname}/config/customize_black.conf
    [ ! -f ${mbroot}/apps/${appname}/config/customize_white.conf ] && touch ${mbroot}/apps/${appname}/config/customize_white.conf
    rm -rf ${mbtmp}/wblist.conf
    rm -rf ${mbtmp}/sscdn.conf
    ipset -N customize_black iphash -!  
    ipset -N customize_white iphash -!
    ipset -N router iphash -!
    ipset -N gfwlist iphash -!

    # 生成自定义黑名单规则，最后4个为tg的ip
    ip_tg="149.154.0.0 91.108.4.0 91.108.56.0 109.239.140.0 67.198.55.0 91.108.4.0/22 91.108.56.0/22 149.154.160.0/20 149.154.164.0/22"
    for ip in $ip_tg
    do
        ipset -! add customize_black $ip >/dev/null 2>&1
    done
    cat ${mbroot}/apps/${appname}/config/customize_black.conf | grep -Ev '^$|^[#;]' | while read line                                                                   
    do         
        if [ -z "$(echo ${line} | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}")" ]; then                                                                                
            echo "ipset=/.${line}/customize_black" >> ${mbtmp}/wblist.conf  
        else
            ipset -! add customize_black ${line} &> /dev/null
        fi                   
    done
    
    # 路由器自身规则
    if [ "$ss_mode" != "homemode" ]; then
        echo "#for router itself" >> ${mbtmp}/wblist.conf
        echo "ipset=/.google.com.tw/router" >> ${mbtmp}/wblist.conf
        echo "ipset=/dns.google.com/router" >> ${mbtmp}/wblist.conf
        echo "ipset=/.github.com/router" >> ${mbtmp}/wblist.conf
        echo "ipset=/.github.io/router" >> ${mbtmp}/wblist.conf
        echo "ipset=/.raw.githubusercontent.com/router" >> ${mbtmp}/wblist.conf
        echo "ipset=/.adblockplus.org/router" >> ${mbtmp}/wblist.conf
        echo "ipset=/.entware.net/router" >> ${mbtmp}/wblist.conf
        echo "ipset=/.apnic.net/router" >> ${mbtmp}/wblist.conf
    fi
    
    # 生成自定义白名单规则
    ip_tg="$lanip $wanip $ss_server $ssg_server $CDN 10.0.0.0 100.64.0.0 127.0.0.0 169.254.0.0 172.16.0.0 192.168.0.0 224.0.0.0 240.0.0.0 223.5.5.5 223.6.6.6 114.114.114.114 114.114.115.115 1.2.4.8 210.2.4.8 112.124.47.27 114.215.126.16 180.76.76.76 119.29.29.29 0.0.0.0"                         
    for ip in $ip_tg; do
        ipset -! add customize_white $ip >/dev/null 2>&1
    done
    cat ${mbroot}/apps/${appname}/config/customize_white.conf | grep -Ev '^$|^[#;]' | while read line
    do
        if [ -z "$(echo ${line} | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}")" ]; then
            echo "ipset=/.${line}/customize_white" >> ${mbtmp}/wblist.conf
        else
            ipset -! add customize_white ${line} &> /dev/null
        fi
    done 
    echo "ipset=/.apple.com/customize_white" >> ${mbtmp}/wblist.conf
    echo "ipset=/.microsoft.com/customize_white" >> ${mbtmp}/wblist.conf
    
    #黑白名单规则
    if [ "$ss_mode" = "whitelist" -o "$ssg_mode" = "frgame" ]; then
        sed -e "s/^/-A nogfwnet &/g" -e "1 i\-N nogfwnet hash:net" ${mbroot}/apps/${appname}/config/chnroute.txt | ipset -R -! 
    elif [ "$ss_mode" = "gfwlist" -o "$ssg_mode" = "cngame" ]; then
        cp -rf ${mbroot}/apps/${appname}/config/gfwlist.conf ${mbtmp}/gfwlist.conf
        sed -i 's/7913/15353/g' ${mbtmp}/gfwlist.conf
        sed -i '/^server/d' ${mbtmp}/gfwlist.conf
        ln -s ${mbtmp}/gfwlist.conf /tmp/etc/dnsmasq.d/gfwlist_ipset.conf
    fi
    # 使规则生效
    ln -s ${mbtmp}/wblist.conf /tmp/etc/dnsmasq.d/wblist.conf    
}

ipset_rules() {
    # ipset deal
    logsh "【$service】" "创建ipset规则..."
    [ ! -f ${mbroot}/apps/${appname}/config/customize_black.conf ] && touch ${mbroot}/apps/${appname}/config/customize_black.conf
    [ ! -f ${mbroot}/apps/${appname}/config/customize_white.conf ] && touch ${mbroot}/apps/${appname}/config/customize_white.conf
    rm -rf ${mbtmp}/wblist.conf
    rm -rf ${mbtmp}/sscdn.conf
    ipset -N customize_black iphash -!  
    ipset -N customize_white iphash -!
    ipset -N router iphash -!
    ipset -N gfwlist iphash -!

    # 生成自定义黑名单规则，最后4个为tg
    ip_tg="149.154.0.0 91.108.4.0 91.108.56.0 109.239.140.0 67.198.55.0 91.108.4.0/22 91.108.56.0/22 149.154.160.0/20 149.154.164.0/22"
    for ip in $ip_tg
    do
        ipset -! add customize_black $ip >/dev/null 2>&1
    done
    cat ${mbroot}/apps/${appname}/config/customize_black.conf | grep -Ev '^$|^[#;]' | while read line                                                                   
    do         
        if [ -z "$(echo ${line} | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}")" ]; then                                                                                
            echo "server=/.${line}/127.0.0.1#15353" >> ${mbtmp}/wblist.conf  
            echo "ipset=/.${line}/customize_black" >> ${mbtmp}/wblist.conf  
        else
            ipset -! add customize_black ${line} &> /dev/null
        fi                   
    done
    
    # 路由器自身规则
    if [ "$ss_mode" != "homemode" ]; then
        echo "#for router itself" >> ${mbtmp}/wblist.conf
        echo "server=/.google.com.tw/127.0.0.1#15353" >> ${mbtmp}/wblist.conf
        echo "ipset=/.google.com.tw/router" >> ${mbtmp}/wblist.conf
        echo "server=/dns.google.com/127.0.0.1#15353" >> ${mbtmp}/wblist.conf
        echo "ipset=/dns.google.com/router" >> ${mbtmp}/wblist.conf
        echo "server=/.github.com/127.0.0.1#15353" >> ${mbtmp}/wblist.conf
        echo "ipset=/.github.com/router" >> ${mbtmp}/wblist.conf
        echo "server=/.github.io/127.0.0.1#15353" >> ${mbtmp}/wblist.conf
        echo "ipset=/.github.io/router" >> ${mbtmp}/wblist.conf
        echo "server=/.raw.githubusercontent.com/127.0.0.1#15353" >> ${mbtmp}/wblist.conf
        echo "ipset=/.raw.githubusercontent.com/router" >> ${mbtmp}/wblist.conf
        echo "server=/.adblockplus.org/127.0.0.1#15353" >> ${mbtmp}/wblist.conf
        echo "ipset=/.adblockplus.org/router" >> ${mbtmp}/wblist.conf
        echo "server=/.entware.net/127.0.0.1#15353" >> ${mbtmp}/wblist.conf
        echo "ipset=/.entware.net/router" >> ${mbtmp}/wblist.conf
        echo "server=/.apnic.net/127.0.0.1#15353" >> ${mbtmp}/wblist.conf
        echo "ipset=/.apnic.net/router" >> ${mbtmp}/wblist.conf
    fi
    
    # 生成自定义白名单规则
    ip_tg="$lanip $wanip $ss_server $ssg_server $CDN 10.0.0.0 100.64.0.0 127.0.0.0 169.254.0.0 172.16.0.0 192.168.0.0 224.0.0.0 240.0.0.0 223.5.5.5 223.6.6.6 114.114.114.114 114.114.115.115 1.2.4.8 210.2.4.8 112.124.47.27 114.215.126.16 180.76.76.76 119.29.29.29 0.0.0.0"                         
    for ip in $ip_tg; do
        ipset -! add customize_white $ip >/dev/null 2>&1
    done
    cat ${mbroot}/apps/${appname}/config/customize_white.conf | grep -Ev '^$|^[#;]' | while read line
    do
        if [ -z "$(echo ${line} | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}")" ]; then
            echo "server=/.${line}/$CDN#53" >> ${mbtmp}/wblist.conf
            echo "ipset=/.${line}/customize_white" >> ${mbtmp}/wblist.conf
        else
            ipset -! add customize_white ${line} &> /dev/null
        fi
    done 
    if [ "$ss_mode" != "homemode" ]; then
        echo "server=/.apple.com/$CDN#53" >> ${mbtmp}/wblist.conf
        echo "ipset=/.apple.com/customize_white" >> ${mbtmp}/wblist.conf
        echo "server=/.microsoft.com/$CDN#53" >> ${mbtmp}/wblist.conf
        echo "ipset=/.microsoft.com/customize_white" >> ${mbtmp}/wblist.conf
    fi
    #黑白名单规则
    if [ "$ss_mode" = "whitelist" -o "$ssg_mode" = "frgame" -o "$ss_mode" = "homemode" ]; then
        sed -e "s/^/-A nogfwnet &/g" -e "1 i\-N nogfwnet hash:net" ${mbroot}/apps/${appname}/config/chnroute.txt | ipset -R -! 
    elif [ "$ss_mode" = "gfwlist" -o "$ssg_mode" = "cngame" ]; then
        cp -rf ${mbroot}/apps/${appname}/config/gfwlist.conf ${mbtmp}/gfwlist.conf
        sed -i 's/7913/15353/g' ${mbtmp}/gfwlist.conf
        ln -s ${mbtmp}/gfwlist.conf /tmp/etc/dnsmasq.d/gfwlist_ipset.conf
    fi
    #加速cdn
    if [ "$ss_mode" != "gfwlist" ]; then
        cat ${mbroot}/apps/${appname}/config/cdn.txt | sed "s/^/server=&\/./g" | sed "s/$/\/&$CDN/g" | sort | awk '{if ($0!=line) print;line=$0}' >>${mbtmp}/sscdn.conf
        ln -s ${mbtmp}/sscdn.conf /tmp/etc/dnsmasq.d/cdn.conf
    fi
    # 使规则生效
    ln -s ${mbtmp}/wblist.conf /tmp/etc/dnsmasq.d/wblist.conf    
}

lan_control() {
    #lan access control
    [ ! -f ${mbroot}/apps/${appname}/config/sscontrol.conf ] && touch ${mbroot}/apps/${appname}/config/sscontrol.conf
    cat ${mbroot}/apps/${appname}/config/sscontrol.conf | while read line
    do
        mac=$(cutsh ${line} 2)
        proxy_name=$(cutsh ${line} 1)
        proxy_mode=$(cutsh ${line} 3)
        game_mode=$(cutsh ${line} 4)
        [ -z "$game_mode" ] && game_mode="$proxy_mode"        
        iptables -t nat -A SHADOWSOCKS -m mac --mac-source $mac $(get_jump_mode $proxy_mode) $(get_action_chain $proxy_mode)
        if [ "$ssgena" == '1' ]; then
            iptables -t mangle -A SHADOWSOCKS -m mac --mac-source $mac $(get_jump_mode $game_mode) $(get_action_chain $game_mode)
            args="[$(get_game_mode $game_mode)]"
        else
            args=""
        fi
        logsh "【$service】" "加载ACL规则:[$proxy_name]代理模式为:[$(get_mode_name $proxy_mode)]$args"
    done
    #default alc mode
    iptables -t nat -A SHADOWSOCKS -p tcp -j $(get_action_chain $ss_proxy_default_mode)
    [ "$ssgena" = '1' ] && iptables -t mangle -A SHADOWSOCKS -p udp -j $(get_action_chain $ss_game_default_mode)   
    result=$(cat ${mbroot}/apps/${appname}/config/sscontrol.conf | wc -l)
    [ "$result" == '0' ] && flag="全部主机" || flag="其余主机"
    [ "$ssgena" == '1' ] && args="[$(get_game_mode $ss_game_default_mode)]" || args=""
    logsh "【$service】" "加载ACL规则:[$flag]代理模式为:[$(get_mode_name $ss_proxy_default_mode)]$args"
}
 
load_nat() {

    logsh "【$service】" "加载iptables的nat规则..."
    iptables -t nat -N SHADOWSOCKS
    iptables -t nat -N SHADOWSOCK
    # iptables -t nat -A SHADOWSOCKS -d 0.0.0.0/8 -j RETURN
    # iptables -t nat -A SHADOWSOCKS -d $lanip/24 -j RETURN
    # iptables -t nat -A SHADOWSOCKS -d $wanip/16 -j RETURN
    # iptables -t nat -A SHADOWSOCKS -d $ss_server -j RETURN
    # iptables -t nat -A SHADOWSOCKS -d $ssg_server -j RETURN 
    # general rules
    iptables -t nat -A SHADOWSOCK -p tcp -m set --match-set customize_white dst -j RETURN
    #router itself
    [ "$ss_mode" != "homemode" ] && iptables -t nat -A OUTPUT -p tcp -m set --match-set router dst -j REDIRECT --to-ports 1081

    case "$ss_mode" in
        "gfwlist")
            logsh "【$service】" "添加国外黑名单规则..."
            iptables -t nat -A SHADOWSOCK -p tcp -m set --match-set customize_black dst -j REDIRECT --to-port 1081
            iptables -t nat -A SHADOWSOCK -p tcp -m set --match-set gfwlist dst -j REDIRECT --to-port 1081
            ;;
        "whitelist")
            logsh "【$service】" "添加国外白名单规则..."                                    
            iptables -t nat -A SHADOWSOCK -p tcp -m set --match-set customize_black dst -j REDIRECT --to-ports 1081
            iptables -t nat -A SHADOWSOCK -p tcp -m set ! --match-set nogfwnet dst -j REDIRECT --to-ports 1081 
            ;;
        "wholemode")
            logsh "【$service】" "添加全局模式iptables规则..."
            iptables -t nat -A SHADOWSOCK -p tcp -j REDIRECT --to-ports 1081
            ;;
        "homemode")
            logsh "【$service】" "添加回国模式规则..."
            iptables -t nat -A SHADOWSOCK -p tcp -m set --match-set customize_black dst -j REDIRECT --to-ports 1081
            iptables -t nat -A SHADOWSOCK -p tcp -m set --match-set nogfwnet dst -j REDIRECT --to-ports 1081 
            ;;
    esac

    if [ "$ssgena" == '1' ]; then
        logsh "【$service】" "加载iptables的udp规则..."
        ip rule add fwmark 0x01/0x01 table 300
        ip route add local 0.0.0.0/0 dev lo table 300
        iptables -t mangle -N SHADOWSOCKS
        iptables -t mangle -N SHADOWSOCK
        # iptables -t mangle -A SHADOWSOCKS -d 0.0.0.0/8 -j RETURN
        # iptables -t mangle -A SHADOWSOCKS -d 127.0.0.1/16 -j RETURN
        # iptables -t mangle -A SHADOWSOCKS -d $lanip/16 -j RETURN
        # iptables -t mangle -A SHADOWSOCKS -d $wanip/16 -j RETURN
        # iptables -t mangle -A SHADOWSOCKS -d $ss_server -j RETURN                                   
        iptables -t mangle -A SHADOWSOCK -p udp -m set --match-set customize_white dst -j RETURN
        # chmod -x /opt/filetunnel/stunserver > /dev/null 2>&1
        # killall -9 stunserver > /dev/null 2>&1
    fi
    case "ssg_mode" in
        "cngame")
            logsh "【$service】" "添加国内游戏iptables规则..."
            iptables -t mangle -A SHADOWSOCK -p udp -m set ! --match-set gfwlist dst -j TPROXY --on-port "$ssg_port" --tproxy-mark 0x01/0x01
            ;;
        "frgame")
            logsh "【$service】" "添加国外游戏iptables规则..."
            iptables -t mangle -A SHADOWSOCK -p udp -m set ! --match-set nogfwnet dst -j TPROXY --on-port "$ssg_port" --tproxy-mark 0x01/0x01
            ;;
    esac

    lan_control
    # last nat
    iptablenu=$(iptables -nvL PREROUTING -t nat | sed 1,2d | sed -n '/KOOLPROXY/=' | head -n1)
    if [ -z "$iptablenu" ];then
        iptablenu=2
    fi
    iptables -t nat -I PREROUTING "$iptablenu" -p tcp -j SHADOWSOCKS
    [ "$ssgena" == '1' ] && iptables -t mangle -A PREROUTING -p udp -j SHADOWSOCKS

}

start_kcp() {
    if [ "$kcp_enable" = '1' ]; then
        [ -z "$ss_kcp_node" ] && logsh "【$service】" "未配置kcp加速节点，不启用kcp！" && return
        logsh "【$service】" "启动kcptun加速主进程($ss_kcp_node)..."
        # [ "$proxy_type" = "v2ray" ] && logsh "【$service】" "启动代理节点类型为v2ray，不启用kcp" && return
        [ -z "$ss_kcp_mtu" ] && ss_kcp_mtu="1350"
        [ -z "$ss_kcp_sndwnd" ] && ss_kcp_sndwnd="128"
        [ -z "$ss_kcp_rcvwnd" ] && ss_kcp_rcvwnd="1024"
        [ -z "$ss_kcp_conn" ] && ss_kcp_conn="1"
        [ -z "$ss_kcp_compon" ] && ss_kcp_compon="1"
        daemon ${mbroot}/apps/${appname}/bin/kcptun \
            --localaddr=127.0.0.1:11183 \
            --remoteaddr=$ss_kcp_node:$ss_kcp_port \
            --key=$ss_kcp_password \
            --crypt=$ss_kcp_crypt \
            --mode=$ss_kcp_mode \
            --mtu=$ss_kcp_mtu \
            --sndwnd=$ss_kcp_sndwnd \
            --rcvwnd=$ss_kcp_rcvwnd \
            --conn=$ss_kcp_conn \
            --nocomp=$ss_kcp_nocomp \
            --dscp=$ss_kcp_dscp \
            --sockbuf=$ss_kcp_sockbuf \
            --smuxbuf=$ss_kcp_smuxbuf \
            --log=${mbroot}/var/log/kcptun.log \
            $ss_kcp_config
        [ $? -ne 0 ] && logsh "【$service】" "启动失败！" && exit 1
        kcp_started=1
    fi
}

detect_status() {
    [ ! -s ${mbroot}/apps/${appname}/config/ssserver.conf -a ! -s ${mbroot}/apps/${appname}/config/ssserver_online.conf ] && logsh "【$service】" "没有添加ss服务器!" && exit 
    result=$(ps | grep -E 'ss-redir|ssr-redir' | grep -v grep | wc -l)
    if [ "$result" != '0'  ];then
        logsh "【$service】" "SS已经在运行！"    
        exit
    fi
}

write_cron_job() {
    cru a "${appname}"_rule "20 5 * * * ${mbroot}/apps/${appname}/scripts/ss_rule_update.sh"
    cru a "${appname}"_online "0 */6 * * * ${mbroot}/apps/${appname}/scripts/ss_online_update.sh"
    cru a "${appname}" "0 6 * * * ${mbroot}/apps/${appname}/scripts/${appname}.sh restart"
}

remote_cron_job() {
    cru d "${appname}"_rule
    cru d "${appname}"_online
    cru d "${appname}"
}

start_haveged () {

    # 启动haveged用于生成随机数
    [ -x ${mbroot}/apps/${appname}/bin/haveged ] && ${mbroot}/apps/${appname}/bin/haveged -w 1024 &> /dev/null

}

start_main_process() {
    if [ "$proxy_type" = "v2ray" ]; then
        logsh "【$service】" "启动代理为v2ray，测试配置文件"
        # rm -rf ${mbroot}/bin/v2ray ${mbroot}/bin/v2ctl
        # ln -s ${mbroot}/apps/${appname}/bin/v2ray ${mbroot}/bin/v2ray
        # ln -s ${mbroot}/apps/${appname}/bin/v2ctl ${mbroot}/bin/v2ctl
        killall -9 v2ray &> /dev/null
        cd ${mbroot}/bin
        result=$(${mbroot}/apps/${appname}/bin/v2ray -test -config="${mbroot}/apps/${appname}/config/v2ray.json" | grep "Configuration OK.")
        [ -z "$result" ] && logsh "【$service】" "配置文件测试失败！" && exit 1
        logsh "【$service】" "启动v2ray主进程($id)..."
        [ -z "$ss_mode" ] && logsh "【$service】" "未配置${appname}运行模式！" && exit 1
        daemon ${mbroot}/apps/${appname}/bin/v2ray -config="${mbroot}/apps/${appname}/config/v2ray.json"
        [ $? -ne 0 ] && logsh "【$service】" "启动失败！" && exit 1
    else
        logsh "【$service】" "启动ss主进程($id)..."
        [ -z "$ss_mode" ] && logsh "【$service】" "未配置${appname}运行模式！" && exit 1
        killall ss-redir &> /dev/null
        killall ssr-redir &> /dev/null
        daemon $APPPATH -b 0.0.0.0 -u -c ${mbroot}/apps/${appname}/config/ss.conf 
        [ $? -ne 0 ] && logsh "【$service】" "启动失败！" && exit 1
    fi

}

start_game_process() {
    if [ "$ssgena" == 1 ]; then     
        if [ "$proxy_type_game" = "v2ray" ]; then
            logsh "【$service】" "游戏加速使用v2ray代理模式！"
            [ -z "$ssg_mode" ] && logsh "【$service】" "未配置游戏进程运行模式！" && exit 1
            ssg_port=1081
        else
            logsh "【$service】" "启动ss游戏进程($ssgid)..."
            [ -z "$ssg_mode" ] && logsh "【$service】" "未配置${appname}游戏运行模式！" && exit 1
            if [ "$ssgid" != "$id" ]; then
                daemon ${mbroot}/apps/${appname}/bin/ssg-redir -b 0.0.0.0 -u -c ${mbroot}/apps/${appname}/config/ssg.conf
                if [ $? -ne 0 ]; then
                    logsh "【$service】" "启动失败！"
                    exit 1
                fi
                ssg_port=1085
            else
                ssg_port=1081
            fi    
        fi
    fi
}

flush_ss_rules() {

    logsh "【$service】" "清除iptables规则..."
    eval `iptables -t nat -S | grep SHADOWSOCK | sed -e "s/-A/iptables -t nat -D/" | sed -e 's/$/;/g'` &> /dev/null
    ip rule del fwmark 0x01/0x01 table 300 &> /dev/null
    ip route del local 0.0.0.0/0 dev lo table 300 &> /dev/null
    iptables -t mangle -D PREROUTING -p udp -j SHADOWSOCKS &> /dev/null
    iptables -t nat -D PREROUTING -p tcp -j SHADOWSOCKS &> /dev/null
    iptables -t mangle -F SHADOWSOCKS &> /dev/null
    iptables -t mangle -X SHADOWSOCKS &> /dev/null
    iptables -t mangle -F SHADOWSOCK &> /dev/null
    iptables -t mangle -X SHADOWSOCK &> /dev/null
    iptables -t nat -F SHADOWSOCK &> /dev/null
    iptables -t nat -X SHADOWSOCK &> /dev/null
    iptables -t nat -F SHADOWSOCKS &> /dev/null
    iptables -t nat -X SHADOWSOCKS &> /dev/null
    iptables -t nat -D PREROUTING -s $lanip/24 -p udp --dport 53 -j DNAT --to $dns_red_ip > /dev/null 2>&1
    eval `iptables -t nat -S | grep "${appname}"-dns | head -1 | sed -e "s/-A/iptables -t nat -D/"` &> /dev/null
    iptables -t nat -D OUTPUT -p tcp -m set --match-set router dst -j REDIRECT --to-ports 1081 &> /dev/null
    chmod +x /opt/filetunnel/stunserver > /dev/null 2>&1
    ipset destroy nogfwnet &> /dev/null
    ipset destroy gfwlist &> /dev/null
    ipset destroy customize_black &> /dev/null
    ipset destroy customize_white &> /dev/null
    ipset destroy router &> /dev/null
    rm -rf ${mbroot}/apps/${appname}/config/ss.conf
    rm -rf ${mbroot}/apps/${appname}/config/dns2socks.conf
    rm -rf ${mbroot}/apps/${appname}/config/ssg.conf
    rm -rf ${mbroot}/apps/${appname}/bin/ssg-redir
    rm -rf ${mbtmp}/wblist.conf
    rm -rf ${mbtmp}/gfwlist.conf
    rm -rf ${mbtmp}/sscdn.conf
    rm -rf /tmp/etc/dnsmasq.d/gfwlist_ipset.conf > /dev/null 2>&1
    rm -rf /tmp/etc/dnsmasq.d/wblist.conf > /dev/null 2>&1
    rm -rf /tmp/etc/dnsmasq.d/cdn.conf &> /dev/null
    # rm -rf ${mbroot}/bin/v2ray &> /dev/null
    # rm -rf ${mbroot}/bin/v2ctl &> /dev/null
    /etc/init.d/dnsmasq restart
    sleep 1
}

# detect_process () {
#     sleep 1
#     [ -n "$(pssh | grep dns2socks)" ] && local dns_process=1
#     if [ "$proxy_type" = "v2ray" ]; then
#         [ -n "$(pssh | grep v2ray)" ] && local v2ray_process=1
#         [ -z "$dns_process" -o -z "$v2ray_process" ] && logsh "【$service】" "进程启动异常，请尝试重新启动或查看日志${mbroot}/var/log/${appname}.log"
#     else 
#         [ -n "$(pssh | grep ss-redir)" ] && local ssredir_process=1
#         [ -n "$(pssh | grep ss-local)" ] && local sslocal_process=1
#         [ -z "$dns_process" -o -z "$ssredir_process" -o -z "$sslocal_process" ] && logsh "【$service】" "进程启动异常，请尝试重新启动或查看日志${mbroot}/var/log/${appname}.log"
#     fi
# }

start() {

    insmod ipt_REDIRECT 2>/dev/null

    detect_status

    start_kcp

    get_config

    start_haveged

    sleep 1

    start_main_process

    start_game_process           

    # [ "$smartdns" = '1' ] && ipset_rules_smartdns || ipset_rules
    ipset_rules

    load_nat

    # [ "$smartdns" != '1' ] && dnsconfig 
    dnsconfig

    #添加定时更新规则
    write_cron_job

    write_firewall_start

    /etc/init.d/dnsmasq restart

    logsh "【$service】" "启动${appname}服务完成，启动失败可查看日志或多次重试！"

    # detect_process

}

stop() {
    
    logsh "【$service】" "关闭ss主进程..."
    killall -9 ss-redir &> /dev/null
    killall -9 ssr-redir &> /dev/null
    killall -9 ssg-redir &> /dev/null
    killall -9 ss-local &> /dev/null
    killall -9 ssr-local &> /dev/null
    killall -9 dns2socks &> /dev/null
    killall -9 v2ray &> /dev/null
    killall -9 haveged &> /dev/null
    killall -9 kcptun &> /dev/null
    #删除定时规则
    remove_firewall_start
    remote_cron_job
    #ps | grep dns2socks | grep -v grep | xargs kill -9 > /dev/null 2>&1
    flush_ss_rules

}

status() {

    result1=$(pssh | grep -v status | grep -c "${appname}")
    #http_status=`curl  -s -w %{http_code} https://www.google.com.hk/images/branding/googlelogo/1x/googlelogo_color_116x41dp.png -k -o /dev/null --socks5 127.0.0.1:1082`
    #if [ "$result" == '0' ] || [ "$http_status" != "200" ]; then
    result2=$(iptables -t nat -S | grep SHADOWSOCK)
    process_count=3
    [ "$ssgena" == '1' ] && ssgflag=", 游戏节点: $ssgid($ssg_mode)"
    if [ "$kcp_enable" == '1' ]; then
        ssgflag="$ssgflag, kcptun($ss_kcp_node):"
        let "process_count++"
	[ "$(pssh | grep -c kcptun)" -eq 1 ] && ssgflag="$ssgflag 运行中" || ssgflag="$ssgflag 未运行"
    fi

    if [ "$proxy_type" == "v2ray" ]; then
        let "process_count--"
    fi

    if [ "$result1" -ge $process_count ]; then
        if [ -n "$result2" ]; then
            status="运行节点: $id($ss_mode)$ssgflag|1" 
        else
            status="ss链路异常，可以尝试重启服务！|0"
        fi
    else
        status="未运行|0"
    fi
    mbdb set $appname.main.status="$status" 

}

case "$1" in
    start) start ;;
    stop) stop ;;
    restart) stop; start ;;
    reload) stop; start ;;
    status) status ;;
esac

