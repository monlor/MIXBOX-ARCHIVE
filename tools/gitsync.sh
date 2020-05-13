#!/bin/bash 
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

	local pack_dir="${1:-mbfiles}"

	rm -rf appstore/

	echo "开始打包插件..."
 	mkdir -p appstore
	ls apps/ | while read line; do
		# 取用缓存数据
		if [ -f ${pack_dir}/applist.txt ]; then
			version_old=`cat ${pack_dir}/applist.txt | grep "$line|" | cut -d'|' -f4`
			version_new=`cat apps/$line/config/$line.uci | grep "version=" | cut -d'=' -f2 | sed -e 's/"//g'`
			if [ "$version_new" != "$version_old" ] || [ -z "$(ls ${pack_dir}/appstore/${line}*)" ]; then
				echo "打包$line..." 
			else
				continue
			fi
		fi
		pack_app $line 
	done
	gerneral_applist

	test ! -d ${pack_dir}/appstore && mkdir -p ${pack_dir}/appstore
	test ! -d ${pack_dir}/temp && mkdir -p ${pack_dir}/temp
	test ! -d ${pack_dir}/appsbin && mkdir -p ${pack_dir}/appsbin

	cp -rf appsbin/* ${pack_dir}/appsbin/
  cp -rf temp/* ${pack_dir}/temp/
  cp -rf install*.sh ${pack_dir}/
  mv -f appstore/* ${pack_dir}/appstore/
  mv -f applist.txt ${pack_dir}/

  rm -rf appstore/
	
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
deploy_lfs() {

	sed -Ei "s#mbfiles/git/raw/[a-z]+#mbfiles/git/raw/$2#" $1/install.sh

	cd $1
	if [ ! -d ".git" ]; then
	  git init
	fi
	git config --local user.email "monlor@qq.com"
	git config --local user.name "monlor"

	git lfs install
  rm -rf .gitattributes
  git lfs track "*_linux_*"
  git lfs track "*_darwin_*"

	if git status &> /dev/null; then
	  git add .
	  git commit -m "$(TZ='Asia/Shanghai' date "+%Y-%m-%d %H:%M:%S")" -a
	fi
	git lfs push "$3" --all
  git push "$3"
}

deploy() {

	sed -Ei "s#mbfiles/git/raw/[a-z]+#mbfiles/git/raw/$2#" $1/install.sh

	cd $1
	if [ ! -d ".git" ]; then
	  git init
	fi
	git config --local user.email "monlor@qq.com"
	git config --local user.name "monlor"

	if git status &> /dev/null; then
	  git add .
	  git commit -m "$(TZ='Asia/Shanghai' date "+%Y-%m-%d %H:%M:%S")" -a
	fi
  git push "$3"
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
	deploy_lfs)
		shift 1
		deploy_lfs $@
		;;
	deploy)
		shift 1
		deploy $@
		;;
esac
