#!/bin/sh 
source /etc/mixbox/bin/base
eval `mbdb export fastdick`


# set_config() {

#     logsh "【$service】" "检查${appname}配置"
#     if [ -z "$uid" ] || [ -z "pwd" ] || [ -z "peerid" ]; then
#         logsh "【$service】" "${appname}用户名或密码为空"
#         exit
#     fi
#     uidline=$(cat ${mbroot}/apps/${appname}/bin/${appname} | grep -n uid | head -1 | cut -d: -f1)
#     pwdline=$(cat ${mbroot}/apps/${appname}/bin/${appname} | grep -n pwd | head -1 | cut -d: -f1)
#     peerline=$(cat ${mbroot}/apps/${appname}/bin/${appname} | grep -n peerid | head -1 | cut -d: -f1)
#     #设置用户名密码
#     sed -i ""$uidline"s#.*#uid=$uid#" ${mbroot}/apps/${appname}/bin/${appname}
#     sed -i ""$pwdline"s#.*#pwd=$pwd#" ${mbroot}/apps/${appname}/bin/${appname}
#     sed -i ""$peerline"s#.*#peerid=$peerid#" ${mbroot}/apps/${appname}/bin/${appname}

# }

start () {
    
    result=$(ps | grep ${mbroot}/apps/${appname}/bin/${appname} | grep -v grep | wc -l)
   	if [ "$result" != '0' ];then
        logsh "【$service】" "${appname}已经在运行！"
        exit 1
    fi
    logsh "【$service】" "正在启动${appname}服务... "
    # open_port
    # write_firewall_start
    daemon ${mbroot}/apps/${appname}/bin/${appname}
    logsh "【$service】" "启动${appname}服务完成！"
    

}

stop () {

    logsh "【$service】" "正在停止${appname}服务... "
    killall -9 ${appname} &> /dev/null
    killall ${mbroot}/apps/${appname}/bin/${appname} > /dev/null 2>&1
    # 

}

status() {

    result=$(pssh | grep ${mbroot}/apps/${appname}/bin/${appname} | grep -v grep | wc -l)
    if [ "$result" == '0' ]; then
        status="未运行|0"
    else
        if [ -f ${mbroot}/var/log/${appname}.log ]; then
            info=$(cat ${mbroot}/var/log/${appname}.log | tail -1)
            message=$(echo "$info" | awk -F ',|\{|\}' '{print$8}' | sed -e 's/\"//g' | cut -d':' -f2)
            province_name=$(echo "$info" | awk -F ',|\{|\}' '{print$10}' | sed -e 's/\"//g' | cut -d':' -f2)
            sp_name=$(echo "$info" | awk -F ',|\{|\}' '{print$14}' | sed -e 's/\"//g' | cut -d':' -f2)
            downstream=$(echo "$info" | awk -F ',|\{|\}' '{print$3}' | sed -e 's/\"//g' | cut -d':' -f2)
            let downstream=$downstream/1024 > /dev/null 2>&1
            if [ "$message" == "提速成功" ]; then
                status="登录用户id: $uid, 运营商: $province_name$sp_name, 下行速度: "$downstream"Mbps|1"
            else
                status="提速异常, 可能还在运行, 请查看日志cat ${mbroot}/var/log/${appname}.log|0"
            fi
        else
            status="提速异常, 账号问题或登录频繁|0"
        fi
    fi
    mbdb set $appname.main.status="$status" 

}

case "$1" in
    start) start ;;
    stop) stop ;;
    restart) stop; start ;;
    reload) close_port && open_port ;;
    status) status ;;
esac
