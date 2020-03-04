#!/bin/sh 
source /etc/mixbox/bin/base
eval `mbdb export transmission`
source ${mbroot}/apps/entware/scripts/functions.sh

create_json() {
    [ "$auth" = '1' ] && auth="true" || auth="false"
    [ ! -d "$path/Torrent" ] && mkdir -p $path/Torrent $path/Torrent/Incomplete $path/Torrent/Watch
    cat > ${mbroot}/apps/${appname}/config/settings.json <<-EOF
{
    "alt-speed-down": 50,
    "alt-speed-enabled": false,
    "alt-speed-time-begin": 540,
    "alt-speed-time-day": 127,
    "alt-speed-time-enabled": false,
    "alt-speed-time-end": 1020,
    "alt-speed-up": 50,
    "bind-address-ipv4": "0.0.0.0",
    "bind-address-ipv6": "::",
    "blocklist-enabled": false,
    "blocklist-url": "http://list.iblocklist.com/?list=bt_level1",
    "cache-size-mb": 2,
    "dht-enabled": true,
    "download-dir": "$path/Torrent",
    "download-queue-enabled": true,
    "download-queue-size": 5,
    "encryption": 0,
    "idle-seeding-limit": 30,
    "idle-seeding-limit-enabled": false,
    "incomplete-dir": "$path/Torrent/Incomplete",
    "incomplete-dir-enabled": false,
    "lpd-enabled": true,
    "message-level": 1,
    "peer-congestion-algorithm": "",
    "peer-id-ttl-hours": 6,
    "peer-limit-global": 40,
    "peer-limit-per-torrent": 8,
    "peer-port": 51413,
    "peer-port-random-high": 65535,
    "peer-port-random-low": 49152,
    "peer-port-random-on-start": false,
    "peer-socket-tos": "lowcost",
    "pex-enabled": true,
    "port-forwarding-enabled": false,
    "preallocation": 1,
    "prefetch-enabled": false,
    "queue-stalled-enabled": true,
    "queue-stalled-minutes": 30,
    "ratio-limit": 2,
    "ratio-limit-enabled": false,
    "rename-partial-files": true,
    "rpc-authentication-required": $auth,
    "rpc-bind-address": "0.0.0.0",
    "rpc-enabled": true,
    "rpc-host-whitelist": "",
    "rpc-host-whitelist-enabled": true,
    "rpc-password": "$password",
    "rpc-port": ${port},
    "rpc-url": "/transmission/",
    "rpc-username": "$username",
    "rpc-whitelist": "127.0.0.1",
    "rpc-whitelist-enabled": false,
    "scrape-paused-torrents-enabled": true,
    "script-torrent-added-enabled": false,
    "script-torrent-added-filename": "",
    "script-torrent-done-enabled": false,
    "script-torrent-done-filename": "",
    "seed-queue-enabled": false,
    "seed-queue-size": 10,
    "speed-limit-down": 100,
    "speed-limit-down-enabled": false,
    "speed-limit-up": 100,
    "speed-limit-up-enabled": false,
    "start-added-torrents": true,
    "trash-original-torrent-files": true,
    "umask": 18,
    "upload-slots-per-torrent": 14,
    "utp-enabled": true,
    "watch-dir": "$path/Torrent/Watch",
    "watch-dir-enabled": true
}
EOF

}

start() {

    [ -n "$(pidof ${appname})" ] && logsh "【$service】" "${appname}已经在运行！" && exit 1
    logsh "【$service】" "正在启动${appname}服务... "
    # cru a "${appname}" "0 6 * * * ${mbroot}/apps/${appname}/scripts/${appname}.sh restart"
    # Scripts Here
    detect_entware || end
    install_entware_app transmission-web transmission-daemon-openssl
    create_json
    [ "$webui" = '1' ] && export TRANSMISSION_WEB_HOME="${mbroot}/apps/${appname}/web" || export TRANSMISSION_WEB_HOME="/opt/etc/transmission/web"
    if [ ! -f ${mbroot}/apps/${appname}/web/index.original.html ]; then
        cp -rf /opt/share/transmission/web/images ${mbroot}/apps/${appname}/web
        cp -rf /opt/share/transmission/web/javascript ${mbroot}/apps/${appname}/web
        cp -rf /opt/share/transmission/web/style ${mbroot}/apps/${appname}/web
        cp -rf /opt/share/transmission/web/index.html ${mbroot}/apps/${appname}/web/index.original.html
    fi
    auto_start_enable ${appname}
    open_port "${port}" 51413
    write_firewall_start
    daemon /opt/bin/transmission-daemon -g ${mbroot}/apps/${appname}/config -e ${mbroot}/var/log/${appname}.log
    if [ $? -ne 0 ]; then
        logsh "【$service】" "启动${appname}服务失败！" && end
    else
        logsh "【$service】" "启动${appname}服务完成！"
    fi
        
}

stop() {

    logsh "【$service】" "正在停止${appname}服务... "
    [ "$enable" == '0' ] && destroy
    close_port
    remove_firewall_start
    kill -9 "$(pidof transmission-daemon)"

}

destroy() {
        
    # End app, Scripts here 
    # cru d "${appname}"
    return

}

end() {

    mbdb set $appname.main.enable=0
    stop && exit 1

}

status() {

    if [ -n "$(pidof transmission-daemon)" ]; then
            status="运行端口号：${port}|1"
    else
            status="未运行|0"
    fi
    mbdb set $appname.main.status="$status" 
}

case "$1" in
    start) start ;;
    stop) stop ;;
    restart) stop; start ;;
    reload) close_port && open_port "${port}" 51413 ;;
    status) status ;;
esac


