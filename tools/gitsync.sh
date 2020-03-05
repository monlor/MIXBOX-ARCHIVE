#!/bin/bash -e
path=./
cd $path
[ $? -ne 0 ] && echo "Change directory failed!" && exit
#find  .  -name  '._*'  -type  f  -print  -exec  rm  -rf  {} \;
find . -name '.DS_Store' | xargs rm -rf
find . -name '._*' | xargs rm -rf
[ "$(uname -s)" = "Darwin" ] && args="\"\"" || args=""

github_url="https://github.com/monlor/MIXBOX.git"
github_raw="https://raw.githubusercontent.com/MIXBOX/master"

sedsh() {
	[ -z "$1" -o -z "$2" -o -z "$3" ] && echo "null sedsh params!" && exit 1
	if [ "$(uname -s)" = "Darwin" ]; then
		if [ "$1" = "s" ]; then
			sed -i "" "s#$2#$3#g" "$4"
		elif [[ "$1" = "d" ]]; then
			sed -i "" "/$2/d" "$3"
		fi
	else
		if [[ "$1" = "s" ]]; then
			sed -i "s#$2#$3#g" "$4"
		elif [[ "$1" = "d" ]]; then
			sed -i "/$2/d" "$3"
		fi
	fi
}

pack_app() {
	local appname=$1
	rm -rf pack/
	mkdir pack/
	[ ! -d apps/$appname ] && echo "未找到插件[$appname]..." && return 1
	eval `cat apps/$appname/config/$appname.uci | grep supports`
	echo $supports | tr ',' '\n' | while read model; do
		cp -rf apps/$appname/ pack/$appname/
		[ ! -d pack/$appname/bin ] && mkdir pack/$appname/bin
		rm -rf pack/$appname/bin/*
		ls apps/$appname/bin 2> /dev/null | grep -E "${model}|^[a-z0-9-]{1,}[^_]$" | while read line; do
			cp -rf apps/$appname/bin/$line pack/$appname/bin/${line/_${model}/}
		done
		# echo "正在打包插件[$appname]平台[$model]，文件名[${appname}_${model}.tar.gz]..."
		tar zcvf ${appname}_${model}.tar.gz -C pack/ ${appname}/ &> /dev/null
		mv -f ${appname}_${model}.tar.gz ./appstore
		rm -rf pack/$appname/
	done
	rm -rf pack/
}

gerneral_applist() {
	rm -rf applist.txt
	ls apps/ | while read line
	do
		eval `cat apps/${line}/config/${line}.uci`
		echo "$appname|$appinfo|$newinfo|$version|$service|$supports" >> applist.txt
	done
}

pack() {

	rm -rf appstore/
	rm -rf mbfiles/

	echo "开始打包插件..."
 	mkdir appstore
	ls apps/ | while read line; do
		pack_app $line
	done
	gerneral_applist

	mkdir mbfiles
	cp -rf appsbin/ mbfiles/appsbin/
  cp -rf temp/ mbfiles/temp/
  cp -rf install.sh mbfiles/
  mv -f appstore/ mbfiles/appstore/
  mv -f applist.txt mbfiles/
	
}

localgit() {
	git add .
	git commit -m "`date "+%Y-%m-%d %H:%M:%S"`"
}

github() {

	git push $github_url $1:$1
}

reset() {
	
	git checkout --orphan latest_branch
 	git add -A
	git commit -am "`date +%Y-%m-%d`"
 	git branch -D master
 	git branch -m master
	
	git rm -r --cached .
}

# $1: path to push
# $2: remote branch name
# $3: remote url with token
# $4: git extra param
deploy() {

	cd $1
  git init
  git config --local user.email "monlor@qq.com"
  git config --local user.name "monlor"
  git add .
  git commit -m "$(TZ='Asia/Shanghai' date "+%Y-%m-%d %H:%M:%S")" -a
  git push "$3" master:"$2" -f "$4"
  git push "$3" master:"$2" -f "$4"

}

case $1 in 
	github)
		github master	
		;;
	localgit)
		localgit
		;;
	push)
		git status && localgit
		github $2
		;;
	pack) 
		shift 1
		pack $@
		;;
	reset)
		reset master
		;;
	deploy)
		shift 1
		deploy $@
esac
