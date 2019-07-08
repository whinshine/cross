#!/bin/bash
backup="/etc/v2ray/vCross_v2ray_backup.txt"
v2ray_transport=$(sed -n '17p' $backup)
v2ray_port=$(sed -n '19p' $backup)
v2ray_id=$(sed -n '21p' $backup)
v2ray_dynamicPort_start=$(sed -n '23p' $backup)
v2ray_dynamicPort_end=$(sed -n '25p' $backup)
domain=$(sed -n '27p' $backup)
caddy_status=$(sed -n '29p' $backup)
shadowsocks_status=$(sed -n '31p' $backup)
ssport=$(sed -n '33p' $backup)
sspass=$(sed -n '35p' $backup)
ssciphers=$(sed -n '37p' $backup)
blocked_ad_status=$(sed -n '39p' $backup)
ws_path_status=$(sed -n '41p' $backup)
ws_path=$(sed -n '43p' $backup)
proxy_site=$(sed '$!d' $backup)
if [[ $caddy_status == "true" ]]; then
	caddy_installed=true
fi
if [[ $shadowsocks_status == "true" ]]; then
	shadowsocks=true
fi
if [[ $blocked_ad_status == "true" ]]; then
	is_blocked_ad=true
fi
if [[ $ws_path_status == "true" ]]; then
	is_ws_path=true
fi

cat >/etc/v2ray/vCross_v2ray_backup.conf <<-EOF
# -----------------------------------
# Warning...Please don't modify or delete this file... Thank you!
# Warning...Please don't modify or delete this file... Thank you!
# Warning...Please don't modify or delete this file... Thank you!
# -----------------------------------

# ---- Attention again ----
# Bro...If you see this...Please don't modify or delete this file

# ---- Tips ----
# Hmm...This file is used to backup some files.
#
#mark=v3
#
#

# ---- V2Ray transport protocol -----
v2ray_transport=$v2ray_transport

#---- V2Ray port -----
v2ray_port=$v2ray_port

#---- UUID -----
v2ray_id=$v2ray_id

#---- alterId -----
alterId=233

#---- V2Ray dynamic port starting -----
v2ray_dynamicPort_start=$v2ray_dynamicPort_start

#---- V2Ray dynamic port ending -----
v2ray_dynamicPort_end=$v2ray_dynamicPort_end

#---- domain name-----
domain=$domain

#---- caddy -----
caddy_status=$caddy_installed

#---- Shadowsocks -----
shadowsocks_status=$shadowsocks

#---- Shadowsocks port -----
ssport=$ssport

#---- Shadowsocks passport -----
sspass=$sspass

#---- Shadowsocks encription protocol -----
ssciphers=$ssciphers

#---- Ad blocking -----
blocked_ad_status=$is_blocked_ad

#---- website disguising -----
path_status=$is_ws_path

#---- disguising path -----
path=$ws_path

#---- disguising website -----
proxy_site=$proxy_site

#---- Socks -----
socks=

#---- Socks port-----
socks_port=153

#---- Socks username -----
socks_username=vCross

#---- Socks password -----
socks_userpass=vCross_Danes

#---- MTProto -----
mtproto=

#---- MTProto port-----
mtproto_port=153

#---- MTProto user key -----
mtproto_secret=lalala

#---- blocking BT -----
ban_bt=true
		EOF
if [[ -f /usr/local/bin/v2ray ]]; then
	cp -f /etc/v2ray/vCross/v2ray/v2ray.sh /usr/local/sbin/v2ray
	chmod +x /usr/local/sbin/v2ray
	rm -rf $backup
	rm -rf /usr/local/bin/v2ray
fi

echo
echo -e " Wow...the script almost finished..."
echo
echo -e "\n $yellow Warning: Please re-login SSH session to avoid errors of missing v2ray commands.$none  \n" && exit 1
echo
exit 1
