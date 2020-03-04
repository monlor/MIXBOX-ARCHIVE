#!/bin/bash 

GIT_BRANCH="$1"

GIT_REF="$2"

rm -rf mbfiles_git/

git clone "${GIT_REF}" mbfiles_git

cd mbfiles_git

git branch | grep -q "* ${GIT_BRANCH}" || git checkout -b "${GIT_BRANCH}"

cp -rf ../mbfiles/* .

git config --local user.email "monlor@qq.com"
git config --local user.name "monlor"


git lfs install

git lfs track "*_darwin_*"

git lfs track "*_linux_*"

git lfs track "*.png"

git config lfs.${CO_REF}/info/lfs.locksverify true

git config lfs.allowincompletepush true

git add .
git commit -m "$(TZ='Asia/Shanghai' date "+%Y-%m-%d %H:%M:%S")" -a

git push "${CO_REF}" "${GIT_BRANCH}":"${GIT_BRANCH}" -f

rm -rf mbfiles_git/