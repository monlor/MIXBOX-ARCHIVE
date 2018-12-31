#!/bin/sh
#copyright by monlor
source /etc/mixbox/bin/base

appname=aria2
[ "$xq" != "R3" -a "$xq" != "R1CM" ] && rm -rf ${mbtmp}/${appname}/lib