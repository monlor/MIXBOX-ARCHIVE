#!/bin/sh  
  
echo "本卸载脚本不会有任何提示，但会很干净的卸载旧的工具箱，GoodBye..."

ls $(uci get monlor.tools.path)/apps 2> /dev/null | while read appname; do
	$(uci get monlor.tools.path)/apps/$appname/script/$appname.sh stop &> /dev/null
done
umount -lf /etc/config &> /dev/null
sed -i '/monlor/d' /etc/crontabs/root &> /dev/null
sed -i '/monlor/d' /etc/firewall.user &> /dev/null
sed -i "/monlor\/config/d" /etc/profile &> /dev/null
sed -i 's#:/etc/monlor/scripts##' /etc/profile &> /dev/null
[ -n "$(uci get monlor.tools.path)" ] && rm -rf $(uci get monlor.tools.path)
rm -rf /etc/monlor &> /dev/null
rm -rf /etc/config/monlor &> /dev/null 