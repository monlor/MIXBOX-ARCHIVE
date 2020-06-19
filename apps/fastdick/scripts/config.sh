eval `mbdb export fastdick`
source /etc/mixbox/bin/base
echo "********* $service ***********"
echo "[${appinfo}]"
[ -z "$(mbdb show entware)" ] && echo "请先安装Entware插件！" && return
readsh "启动${appname}服务[1/0] " "enable" "1"
if [ "$enable" == '1' ]; then
  uid=$(mbdb get ${appname}.main.uid) || uid="空"
  pwd=$(mbdb get ${appname}.main.pwd) || pwd="空"
  peerid=$(mbdb get ${appname}.main.peerid) || peerid="空"
  echo "[请按https://github.com/fffonion/Xunlei-Fastdick这里的教程运行swjsq.py并找到运行成功后生成的swjsq_wget.sh文件，复制其所有内容编辑到配置里]"
  read -p "修改${appname}配置(将开始使用vim编辑快鸟运行脚本)？[1/0]" res
  if [ "$res" == '1' ]; then
    echo "[提示]按i开始编辑，编辑完按ESC键再按:wq即可保存退出[注意冒号]"
    read -p "清空文件之后再编辑？[1/0]" res
    [ "$res" = '1' ] && cat /dev/null > ${mbroot}/apps/${appname}/bin/${appname}
    if type vim &> /dev/null; then
      vim ${mbroot}/apps/${appname}/bin/${appname}
    else
      vi ${mbroot}/apps/${appname}/bin/${appname}
    fi
  fi
  readsh "请输入${appname}外网访问配置[1/0]" "openport" "1"
  readsh "重启${appname}服务[1/0] " "res" "1"
  [ "$res" != '0' ] && exit 0
fi
exit 1