#!/bin/bash
case $v2ray_transport in
[5-8])
	_transport=$(($v2ray_transport + 1))
	;;
9 | 1[0-5])
	_transport=$(($v2ray_transport + 9))
	;;
16)
	_transport=5
	;;
17)
	_transport=1
	;;
*)
	_transport=$v2ray_transport
	;;
esac

if [[ $v2ray_transport == 17 ]]; then
	v2ray_id=$(cat /proc/sys/kernel/random/uuid)
fi

cat >$backup <<-EOF
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
mark=v3
#
#

# ---- V2Ray transport protocol -----
v2ray_transport=$_transport

#---- V2Ray port -----
v2ray_port=$v2ray_port

#---- UUID -----
v2ray_id=$v2ray_id

#---- alterId -----
alterId=$alterId

#---- V2Ray dynamic port starting -----
v2ray_dynamicPort_start=$v2ray_dynamicPort_start

#---- V2Ray dynamic port ending -----
v2ray_dynamicPort_end=$v2ray_dynamicPort_end

#---- domain name -----
domain=$domain

#---- caddy -----
caddy=$caddy_status

#---- Shadowsocks -----
shadowsocks=$shadowsocks_status

#---- Shadowsocks port -----
ssport=$ssport

#---- Shadowsocks passport -----
sspass=$sspass

#---- Shadowsocks encription protocol -----
ssciphers=$ssciphers

#---- Ad blocking -----
ban_ad=$blocked_ad_status

#---- website disguising -----
path_status=$path_status

#---- disguising path -----
path=$path

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

. $backup
