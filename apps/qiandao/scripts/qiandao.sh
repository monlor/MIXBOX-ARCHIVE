#!/bin/sh 
source /etc/mixbox/bin/base
eval `mbdb export qiandao`

SETTING_FILE="${mbroot}/apps/${appname}/bin/cookie.txt"
[ -z "$qiandao_time" ] && qiandao_time="8"

generate_cookie_conf() {

  cp -f ${mbroot}/apps/${appname}/config/cookie_template.txt ${SETTING_FILE}

  local qiandao_setting=""
  local qiandao_enable=""

  echo "${qiandao_support}" | tr ' ' '\n' | while read line; do
  test -z "${line}" && continue
  qiandao_setting="$(parse_str qiandao_${line}_setting)"
  qiandao_enable="$(parse_str qiandao_${line})"
  # 该签到网站未启用签到程序时，将cookie置为空
  [ "${qiandao_enable}" != "1" ] && qiandao_setting="" || qiandao_setting="$(base_decode "${qiandao_setting}")"
  sed -i "s/##${line}_cookie##/${qiandao_setting}/" ${SETTING_FILE}
  done

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

