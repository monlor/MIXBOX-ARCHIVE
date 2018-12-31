#!/bin/sh 
source /etc/mixbox/bin/base
eval `mbdb export httpfile`
source /etc/mixbox/apps/entware/scripts/functions.sh

# port=
BIN=/opt/sbin/nginx
NGINXCONF=/opt/etc/nginx/nginx.conf
CONF=/opt/etc/nginx/vhost/httpfile.conf
ports=""

open_ports() {
	mbdb get $appname.main.ports | tr ',' '\n' | while read line; do
		[ -z "${line}" ] && continue
		open_port "${line}"
	done
}

set_config() {

	result=$(/opt/bin/opkg list-installed | grep -c "^nginx")
	[ "$result" == '0' ] && /opt/bin/opkg install nginx
 	logsh "【$service】" "生成nginx配置信息..."
	#修改nginx配置文件
	[ ! -x "${mbroot}/apps/${appname}/bin" ] && logsh "【$service】" "nginx未安装！" && end
	cat > ${mbtmp}/nginx.conf <<-\EOF
	user root;
	pid /opt/var/run/nginx.pid;
	worker_processes auto;
	worker_rlimit_nofile 65535;

	events {
	    worker_connections 1024;
	}

	http {

	    include                mime.types;
	    sendfile               on;
	    default_type           application/octet-stream;
	    keepalive_timeout      65;
	    client_max_body_size   4G;
	    include                /opt/etc/nginx/vhost/*.conf;

	}
	EOF
	umountsh $NGINXCONF
	mount --bind ${mbtmp}/nginx.conf $NGINXCONF

	# 生成配置文件
	logsh "【$service】" "生成${appname}配置文件..."
	[ ! -d "/opt/etc/nginx/vhost" ] && mkdir -p /opt/etc/nginx/vhost
	[ -z "`mbdb keys $appname.web`" ] && logsh "【$service】" "未添加${appname}配置！" && end
	rm -rf ${mbtmp}/${appname}.conf
	mbdb keys $appname.web | while read line
	do
		port=$(mbdb get $appname.web.${line} | cutsh 1)
		path=$(mbdb get $appname.web.${line} | cutsh 2)
		cat >> ${mbtmp}/${appname}.conf <<-\EOF
		server {
		        listen  port;
		        server_name  httpfile;
		        charset utf-8;
		        location / {
		            root   directory;
		            index  index.php index.html index.htm;
		            autoindex on;
		            autoindex_exact_size off;
		            autoindex_localtime on;
		        }	     
		}
		EOF
		sed -i "s/port/${port}/" ${mbtmp}/${appname}.conf
		sed -i "s#directory#$path#" ${mbtmp}/${appname}.conf
		logsh "【$service】" "加载${appname}配置:[端口号:${port}, 路径:$path]"
    	ports="${port}s${port},"
	done
	mbdb set $appname.main.ports="$(mbdb values $appname.web | cutsh 1 | tr '\n' ',')"
	rm -rf ${mbroot}/apps/${appname}/config
	ln -s ${mbtmp}/${appname}.conf ${mbroot}/apps/${appname}/config
}

start () {

	result=$(ps | grep nginx |  grep -v sysa | grep -v grep | wc -l)
    	if [ "$result" != '0' ] && [ -f "${mbroot}/apps/${appname}/config" ];then
		logsh "【$service】" "${appname}已经在运行！"
		exit 1
	fi
	# result=$(ps | grep entware.sh | grep -v grep | wc -l)
 #    	if [ "$result" != '0' ];then
	# 	logsh "【$service】" "检测到【Entware】正在运行，现在启用${appname}可能会冲突"
	# 	exit 1
	# fi
	logsh "【$service】" "正在启动${appname}服务... "
	# 检查entware
	result1=$(mbdb show entware)
	result2=$(ls /opt | grep etc)
	if [ -z "$result1" ] || [ -z "$result2" ]; then 
		logsh "【$service】" "检测到【Entware】服务未启动或未安装"
		end
	else
		result3=$(echo $PATH | grep opt)
		[ -z "$result3" ] && export PATH=/opt/bin/:/opt/sbin:$PATH
	fi

	set_config
	open_ports
	write_firewall_start
	#添加entware识别
	auto_start_enable
	
	[ ! -f "/opt/etc/init.d/S80nginx" ] && logsh "【$service】" "未找到启动脚本！" && exit
	/opt/etc/init.d/S80nginx stop &> /dev/null
	/opt/etc/init.d/S80nginx start > /dev/null
	if [ $? -ne 0 ]; then
        logsh "【$service】" "启动${appname}服务失败！"
	else
    	logsh "【$service】" "启动${appname}服务完成！"
    fi

}

stop () {

	logsh "【$service】" "正在停止${appname}服务... "
	[ "$enable" == '0' ] && destroy
	close_port
	remove_firewall_start
	rm -rf ${mbtmp}/${appname}.conf ${mbroot}/apps/${appname}/config
	umountsh $NGINXCONF
	
}

destroy() {
	#清除entware识别
	auto_start_disable
}

end() {

    /opt/etc/init.d/S80nginx stop > /dev/null
    stop && exit 1

}

status() {

	result=$(pssh | grep nginx | grep -v sysa | grep -v grep | wc -l)
	if [ "$result" != '0' ] && [ -f "${mbroot}/apps/${appname}/config" ]; then
		status="运行中|1"
	else
		status="未运行|0"
	fi
	mbdb set $appname.main.status="$status" 

}

case "$1" in
    start) start ;;
    stop) stop ;;
    restart) stop; start ;;
    reload) close_port && open_ports ;;
    status) status ;;
esac
