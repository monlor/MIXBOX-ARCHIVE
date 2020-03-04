#!/bin/sh 
source /etc/mixbox/bin/base
eval `mbdb export kodexplorer`
source /etc/mixbox/apps/entware/scripts/functions.sh

# port=81
PHPBIN=/opt/bin/spawn-fcgi
NGINXBIN=/opt/sbin/nginx
NGINXCONF=/opt/etc/nginx/nginx.conf
PHPCONF=/opt/etc/php.ini
WWW=/opt/share/nginx/html/kodexplorer
CONF="/opt/etc/nginx/vhost/kodexplorer.conf"
path=$(mbdb get ${appname}.main.path)
port=$(mbdb get ${appname}.main.port) || port=81
lanip=$(uci get network.lan.ipaddr)
opkg_list="php7-cgi php7-mod-curl php7-mod-gd php7-mod-iconv php7-mod-json php7-mod-mbstring php7-mod-opcache php7-mod-session php7-mod-zip nginx spawn-fcgi zoneinfo-core zoneinfo-asia libxml2 unzip"


config_php() {
	logsh "【$service】" "修改php配置信息..."
	result=$(/opt/bin/opkg list-installed | grep -c "^php7-cgi")
	[ "$result" == '0' ] && logsh "【$service】" "php未安装！" && end
	cp $PHPCONF ${mbtmp}/php.ini
	sed -i "/doc_root/d" ${mbtmp}/php.ini
	sed -i "s#.*open_basedir.*#open_basedir = \"$WWW\"#" ${mbtmp}/php.ini
	sed -i 's/memory_limit = 8M/memory_limit = 20M/' ${mbtmp}/php.ini
	sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 2000M/' ${mbtmp}/php.ini
	umountsh $PHPCONF
	mount --bind ${mbtmp}/php.ini $PHPCONF
	# echo "<?php phpinfo(); ?>" > $WWW/info.php
	# rm -rf $WWW/index.html
}

config_nginx() {
	logsh "【$service】" "生成nginx配置信息..."
	#修改nginx配置文件
	[ ! -x "$NGINXBIN" ] && logsh "【$service】" "nginx未安装！" && end
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

	#生成配置文件
	[ ! -d "/opt/etc/nginx/vhost" ] && mkdir -p /opt/etc/nginx/vhost
	cat > ${mbtmp}/${appname}.conf <<-\EOF
	server {
	        listen  81;
	        server_name  kodexplorer;

	        location / {
	            root   /opt/share/nginx/html/kodexplorer;
	            index  index.php index.html index.htm;
	        }

	        error_page   500 502 503 504  /50x.html;
	        location = /50x.html {
	            root   html;
	        }

	        location ~ \.php$ {
	            root           /opt/share/nginx/html/kodexplorer;
	            fastcgi_pass   127.0.0.1:9009;
	            fastcgi_index  index.php;
	            fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
	            include        fastcgi_params;
	        }
	}
	EOF
	sed -i "s/81/${port}/" ${mbtmp}/${appname}.conf
	rm -rf /opt/etc/nginx/vhost/${appname}.conf
	ln -s ${mbtmp}/${appname}.conf /opt/etc/nginx/vhost/${appname}.conf
}

detect_webfiles() {
	if [ ! -d $WWW/app/kod/ ]; then
		logsh "【$service】" "未检测到${appname}文件，正在下载"
		[ ! -d $WWW ] && mkdir $WWW
		wgetsh $WWW/kodexplorer.zip $mburl/appsbin/kodexplorer.zip
		[ $? -ne 0 ] && logsh "【$service】" "${appname}文件下载失败" && stop
		unzip $WWW/kodexplorer.zip -d $WWW
		rm -rf $WWW/kodexplorer.zip
	fi
}

detect_opkg() {
	for i in $opkg_list 
	do
		result=$(/opt/bin/opkg list-installed | grep -c "^$i")
		[ "$result" == '0' ] && /opt/bin/opkg install $i
	done
}

mount_admin_root() {
	if [ -n "$path" ]; then
		logsh "【$service】" "挂载${appname}管理目录"
		if [ -d $WWW/data/User/admin/home ]; then
			[ ! -d "$path" ] && mkdir -p $path
			umountsh $WWW/data/User/admin/home
			mount --bind "$path" $WWW/data/User/admin/home
		else
			logsh "【$service】" "检测到${appname}服务未配置，无法挂载管理目录"
		fi
	fi
}

start () {

	result=$(ps | grep -E 'nginx|php-cgi' | grep -v sysa | grep -v grep | wc -l)
    	if [ "$result" != '0' -a -f /opt/etc/nginx/vhost/${appname}.conf ];then
		logsh "【$service】" "${appname}已经在运行！"
		exit 1
	fi
	# result=$(ps | grep entware.sh | grep -v grep | wc -l)
 #    	if [ "$result" != '0' ];then
	# 	logsh "【$service】" "检测到【Entware】正在运行，现在启用${appname}可能会冲突"
	# 	exit 1
	# fi
	logsh "【$service】" "正在启动${appname}服务... "
	#检查entware状态
	result1=$(mbdb show entware)
	result2=$(ls /opt | grep etc)
	if [ -z "$result1" ] || [ -z "$result2" ]; then 
		logsh "【$service】" "检测到【Entware】服务未启动或未安装"
		end
	else
		result3=$(echo $PATH | grep opt)
		[ -z "$result3" ] && export PATH=/opt/bin/:/opt/sbin:$PATH
	fi

	detect_opkg

	config_nginx

	config_php

	detect_webfiles
	
	mount_admin_root

	#添加entware识别
	auto_start_enable
	
	open_port
    write_firewall_start
	/opt/etc/init.d/S80nginx stop &> /dev/null

	/opt/etc/init.d/S80nginx start > /dev/null
	if [ $? -ne 0 ]; then
		logsh "【$service】" "启动nginx服务失败！"
	fi
	daemon $PHPBIN -a 127.0.0.1 -p 9009 -C 2 -f /opt/bin/php-cgi > /dev/null
	if [ $? -ne 0 ]; then
        logsh "【$service】" "启动php服务失败！"
    fi
    logsh "【$service】" "${appname}服务启动完成"
    logsh "【$service】" "请在浏览器中访问[http://$lanip:${port}]配置"

}

stop () {

	logsh "【$service】" "正在停止${appname}服务... "
	[ "$enable" == '0' ] && destroy
	result=$(mbdb get mixbox.httpfile.enable)
	killall php-cgi &> /dev/null
	# kill -9 $(ps | grep 'nginx' | grep -v sysa | grep -v grep | awk '{print$1}') > /dev/null 2>&1
	close_port
	remove_firewall_start
	#清除关于entware配置
	logsh "【$service】" "关闭或卸载不会删除opkg的软件包和${appname}的web文件！"
	umountsh $PHPCONF && rm -rf ${mbtmp}/php.ini
	umountsh $NGINXCONF && rm -rf ${mbtmp}/nginx.conf
	rm -rf ${mbtmp}/${appname}.conf /opt/etc/nginx/vhost/${appname}.conf
	umountsh $WWW/data/User/admin/home 

}

end() {

    /opt/etc/init.d/S80nginx stop > /dev/null
    stop && exit 1

}

destroy() {
	#清除entware识别
	auto_start_disable
}


status() {

	result=$(pssh | grep -E 'nginx|php-cgi' | grep -v sysa | grep -v grep | wc -l)
	if [ "$result" -ge '5' ] && [ -f "/opt/etc/nginx/vhost/${appname}.conf" ]; then
		status="运行端口号: ${port}, 管理目录: $path|1"
	else
		status="未运行|0"
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

