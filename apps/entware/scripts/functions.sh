
auto_start_enable() {
    [ -z "$1" ] && return 1
    mbdb set entware.app."$1" "1"
}

auto_start_disable() {
    [ -z "$1" ] && return 1
    mbdb del entware.app."$1"
}

detect_entware() {
    result1=$(mbdb show entware)
    result2=$(ls /opt | grep etc)
    if [ -z "$result1" ] || [ -z "$result2" ]; then 
        logsh "【$service】" "检测到【Entware】服务未启动或未安装"
        return 1
    else
        result3=$(echo $PATH | grep opt)
        [ -z "$result3" ] && export PATH=/opt/bin:/opt/sbin:$PATH
    fi
    return 0
}

install_entware_app() {
    for i in $@; do
        result=$(/opt/bin/opkg list-installed | grep -c "^$i")
        if [ "$result" == '0' ]; then
            /opt/bin/opkg install $i 
            [ $? -ne 0 ] && logsh "【$service】" "程序$i安装失败！" && return 1
        fi
    done
    return 0
}