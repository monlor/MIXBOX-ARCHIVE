#!/bin/sh 
source /etc/mixbox/bin/base
eval `mbdb export qiandao`


SETTING_FILE="${mbtmp}/cookie.txt"
[ -z "$qiandao_time" ] && qiandao_time="8"


generate_cookie_conf() {

        rm -rf $SETTING_FILE
        rm -rf ${mbroot}/apps/${appname}/bin/cookie.txt
        [ "$qiandao_koolshare" == "1" ] && [ -n "$qiandao_koolshare_setting" ] && echo -e "\"koolshare\"=$qiandao_koolshare_setting" >> $SETTING_FILE
        [ "$qiandao_baidu" == "1" ] && [ -n "$qiandao_baidu_setting" ] && echo -e "\"baidu\"=$qiandao_baidu_setting" >> $SETTING_FILE
        [ "$qiandao_v2ex" == "1" ] && [ -n "$qiandao_v2ex_setting" ] && echo -e "\"v2ex\"=$qiandao_v2ex_setting" >> $SETTING_FILE
        [ "$qiandao_hostloc" == "1" ] && [ -n "$qiandao_hostloc_setting" ] && echo -e "\"hostloc\"=$qiandao_hostloc_setting" >> $SETTING_FILE
        [ "$qiandao_acfun" == "1" ] && [ -n "$qiandao_acfun_setting" ] && echo -e "\"acfun\"=$qiandao_acfun_setting" >> $SETTING_FILE
        [ "$qiandao_bilibili" == "1" ] && [ -n "$qiandao_bilibili_setting" ] && echo -e "\"bilibili\"=$qiandao_bilibili_setting" >> $SETTING_FILE
        [ "$qiandao_smzdm" == "1" ] && [ -n "$qiandao_smzdm_setting" ] && echo -e "\"smzdm\"=$qiandao_smzdm_setting" >> $SETTING_FILE
        [ "$qiandao_xiami" == "1" ] && [ -n "$qiandao_xiami_setting" ] && echo -e "\"xiami\"=$qiandao_xiami_setting" >> $SETTING_FILE
        [ "$qiandao_163music" == "1" ] && [ -n "$qiandao_163music_setting" ] && echo -e "\"163music\"=$qiandao_163music_setting" >> $SETTING_FILE
        [ "$qiandao_miui" == "1" ] && [ -n "$qiandao_miui_setting" ] && echo -e "\"miui\"=$qiandao_miui_setting" >> $SETTING_FILE
        [ "$qiandao_52pojie" == "1" ] && [ -n "$qiandao_52pojie_setting" ] && echo -e "\"52pojie\"=$qiandao_52pojie_setting" >> $SETTING_FILE
        [ "$qiandao_kafan" == "1" ] && [ -n "$qiandao_kafan_setting" ] && echo -e "\"kafan\"=$qiandao_kafan_setting" >> $SETTING_FILE
        [ "$qiandao_right" == "1" ] && [ -n "$qiandao_right_setting" ] && echo -e "\"right\"=$qiandao_right_setting" >> $SETTING_FILE
        [ "$qiandao_mydigit" == "1" ] && [ -n "$qiandao_mydigit_setting" ] && echo -e "\"mydigit\"=$qiandao_mydigit_setting" >> $SETTING_FILE
        if [ -f "$SETTING_FILE" ];then
                ln -sf $SETTING_FILE ${mbroot}/apps/${appname}/bin/cookie.txt
        else
                logsh "【$service】" "检测到你没有填写任何cookie配置！关闭插件！" 
                mbdb set $appname.main.enable=0
                
                exit 1
        fi

}

add_cron() {

        logsh "【$service】" "添加签到定时任务，每天$qiandao_time点自动签到..."
        cru a ${appname} "1 $qiandao_time * * * ${mbroot}/apps/${appname}/scripts/${appname}.sh restart"

}

del_cron() {

        logsh "【$service】" "删除签到定时任务！"
        cru d ${appname}

}

start() {

        [ -n "$(pidof ${appname})" ] && logsh "【$service】" "${appname}已经在运行！" && exit 1
        logsh "【$service】" "正在启动${appname}服务... "
        # Scripts Here
        generate_cookie_conf
        add_cron
        # open_port
    # write_firewall_start
        if [ "$qiandao_action" == '2' ]; then
                i=4
                while(true)
                do
                        echo "-------------------------------"
                        cd ${mbroot}/apps/${appname}/bin && ./${appname} 2>&1 | tee ${mbroot}/var/log/${appname}.log
                        echo "-------------------------------"
                        if [ -z "$(cat ${mbroot}/var/log/${appname}.log | grep panic)" ]; then 
                                break 
                        else
                                logsh "【$service】" "出错了，1秒后尝试重新启动..."
                                sleep 1
                        fi
                        let i=$i-1
                        [ "$i" -eq 0 ] && logsh "【$service】" "启动${appname}服务失败！" && exit 1
                done
        else
                mbdb set $appname.main.qiandao_action='2'
                
        fi
        
        logsh "【$service】" "启动${appname}服务完成！"
        status
        
}

stop() {

        logsh "【$service】" "正在停止${appname}服务... "
        rm -rf $SETTING_FILE
        rm -rf ${mbroot}/apps/${appname}/bin/cookie.txt
        # killall -9 ${appname} &> /dev/null
        [ "$enable" == '0' ] && destroy

}

destroy() {
        
        # End app, Scripts here 
        del_cron
        return

}

status() {

        if [ -n "$(cru l | grep ${appname})" -a -f ${mbroot}/apps/${appname}/bin/cookie.txt ]; then
                status="运行中，每天$qiandao_time点自动签到|1"
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

