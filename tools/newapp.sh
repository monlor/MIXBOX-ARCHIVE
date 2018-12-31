#!/bin/sh
# 快速生成新app
dir=./apps
appname="$1"
service="$2"
appinfo="$3"
needver=""
[ -z "${appname}" -o -z "$service" -o -z "${appinfo}" ] && echo "信息为空(插件名，服务名，介绍)！" && exit
[ -d $dir/${appname} ] && echo "插件已存在！" && exit
cd $dir || (mkdir -p $dir && cd $dir)
mkdir -p ${appname}
mkdir -p ${appname}/bin
mkdir -p ${appname}/config
mkdir -p ${appname}/scripts
echo "生成插件uci配置文件..."
cat > ${appname}/config/${appname}.uci <<-EOF
service="$service"
appname="${appname}"
needver="0.0.1"
backupfiles=""
supports="linux_arm,linux_mips,linux_x86_64,darwin_linux_x86_64"
appinfo="${appinfo}"
newinfo=""
EOF
echo "生成工具箱配置文件..."
cat > ${appname}/config/mixbox.conf <<EOF
#------------------【$2】--------------------
${appname}() {

    eval \`mbdb export ${appname}\`
    source "\$(mbdb get mixbox.main.path)"/bin/base
    echo "********* \$service ***********"
    echo "[\${appinfo}]"
    readsh "启动\${appname}服务[1/0] " "enable" "1"
    if [ "\$enable" == '1' ]; then
            # Scripts Here
            
            # readsh "请输入\${appname}外网访问配置[1/0]" "openport" "0"
            readsh "重启\${appname}服务[1/0] " "res" "1"
            [ "\$res" = '1' -o -z "\$res" ] && \${mbroot}/apps/\${appname}/scripts/\${appname}.sh restart
    else
            \${mbroot}/apps/\${appname}/scripts/\${appname}.sh stop
    fi

}
#------------------【$2】--------------------
EOF
echo "生成插件运行脚本..."
cat > ${appname}/scripts/${appname}.sh <<-EOF
#!/bin/sh 
eval \`mbdb export ${appname}\`
source "\$(mbdb get mixbox.main.path)"/bin/base
port=""

start() {

    [ -n "\$(pidof \${appname})" ] && logsh "【\$service】" "\${appname}已经在运行！" && exit 1
    logsh "【\$service】" "正在启动\${appname}服务... "
    # cru a "\${appname}" "0 6 * * * \${mbroot}/apps/\${appname}/scripts/\${appname}.sh restart"
    # Scripts Here
    
    # open_port
    # write_firewall_start
    daemon \${mbroot}/apps/\${appname}/bin/\${appname}
    if [ \$? -ne 0 ]; then
        logsh "【\$service】" "启动\${appname}服务失败！" && end
    else
        logsh "【\$service】" "启动\${appname}服务完成！"
        # logsh "【\$service】" "请在浏览器打开地址：http://\$lanip:\$port"
    fi
        
}

stop() {

    logsh "【\$service】" "正在停止\${appname}服务... "
    [ "\$enable" == '0' ] && destroy
    # close_port
    # remove_firewall_start
    killall -9 \${appname} &> /dev/null

}

destroy() {
        
    # End app, Scripts here 
    # cru d "\${appname}"
    return

}

end() {

    mbdb set \${appname}.main.enable=0
    stop && exit 1

}

status() {

    if [ -n "\$(pidof \${appname})" ]; then
            status="运行中|1"
    else
            status="未运行|0"
    fi
    mbdb set \${appname}.main.status="\$status" 
}

case "\$1" in
    start) start ;;
    stop) stop ;;
    restart) stop; start ;;
    reload) close_port && open_port ;;
    status) status ;;
esac

EOF
