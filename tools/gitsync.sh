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
coding_url="https://git.dev.tencent.com/monlor/MIXBOX.git"
coding_raw="https://dev.tencent.com/u/monlor/p/MIXBOX/git/raw/master"

sedsh() {
	[ -z "$1" -o -z "$2" -o -z "$3" ] && echo "null sedsh params!" && exit 1
	if [ "$(uname -s)" = "Darwin" ]; then
		if [ "$1" = "s" ]; then
			sed -i "" "s#$2#$3#g" "$4"
		elif [[ "$1" = "d" ]]; then
			sed -i "" "#$2#d" "$3"
		fi
	else
		if [[ "$1" = "s" ]]; then
			sed -i "s#$2#$3#g" "$4"
		elif [[ "$1" = "d" ]]; then
			sed -i "#$2#d" "$3"
		fi
	fi
}

version() {
	local appname="$1"
	eval `cat apps/${appname}/config/${appname}.uci | grep version`
	# sed -i $args '/version/d' apps/${appname}/config/${appname}.uci
	sedsh "d" "version" "apps/${appname}/config/${appname}.uci"
	num1=$(echo "$version" | cut -d'.' -f1)
	num2=$(echo "$version" | cut -d'.' -f2)
	num3=$(echo "$version" | cut -d'.' -f3)
	if [ "$num3" -eq '9' ]; then
		if [[ "$num2" -eq '9' ]]; then
			let num1=$num1+1
			num2=0
			num3=0
		else
			let num2=$num2+1
			num3=0
		fi
	else
		let num3=$num3+1
	fi
	echo "version=\"$num1.$num2.$num3\"" >> apps/${appname}/config/${appname}.uci
}

pack_app() {
	local appname=$1
	rm -rf pack/
	mkdir pack/
	[ ! -d apps/$appname ] && echo "未找到插件[$appname]..." && return 1
	eval `cat apps/$appname/config/$appname.uci | grep supports`
	echo $supports | tr ',' '\n' | while read model; do
		cp -rf apps/$appname/ pack/
		[ ! -d pack/$appname/bin ] && mkdir pack/$appname/bin
		rm -rf pack/$appname/bin/*
		ls apps/$appname/bin 2> /dev/null | grep -E "${model}|^[a-z]{1,}[^_]$" | while read line; do
			cp -rf apps/$appname/bin/$line pack/$appname/bin/${line/_${model}/}
		done
		echo "正在打包插件[$appname]平台[$model]，文件名[${appname}_${model}.tar.gz]..."
		tar zcvf ${appname}_${model}.tar.gz -C pack/ ${appname}/ &> /dev/null
		[ ! -d ./appstore/history ] && mkdir ./appstore/history
		mv ./appstore/${appname}_${model}.tar.gz ./appstore/history &> /dev/null
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

	case "$1" in
		all )
			ls apps/ | while read line; do
				[ "$2" = "-v" ] && version ${line}
				pack_app $line && sleep 1
			done
			;;
		* )
			[ -z "$1" ] && echo "未输入插件名！" && exit
			[ "$2" = "-v" ] && version $1
			pack_app $1
			;;
	esac
	gerneral_applist
	
}

localgit() {
	git add .
	git commit -m "`date +%Y-%m-%d`"
}

github() {

	# sed -i $args "s#^mburl.*#mburl=\"$github_raw\"#" ./install.sh
	sedsh "s" "^mburl.*" "mburl=\"$github_raw\"" "./install.sh"
	localgit
	git remote rm origin
	git remote add origin $github_url
	git push origin master 
}

coding() {

	# sed -i $args "s#^mburl.*#mburl=\"$coding_raw\"#" ./install.sh
	sedsh "s" "^mburl.*" "mburl=\"$coding_raw\"" "./install.sh"
	localgit
	git remote rm origin
	git remote add origin $coding_url
	git push origin master 
}

reset() {
	
	git checkout --orphan latest_branch
   	git add -A
  	git commit -am "`date +%Y-%m-%d`"
   	git branch -D master
   	git branch -m master
	
   #	git push -f origin master
	# github
	# coding
	git rm -r --cached .
}

case $1 in 
	all) 
		github
		coding
		;;
	github)
		github		
		;;
	coding)
		coding
		;;
	push)
		github
		coding
		;;
	pack) 
		shift 1
		pack $@
		;;
	reset)
		reset
		;;
esac
