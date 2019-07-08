#!/bin/bash
uuid=$(cat /proc/sys/kernel/random/uuid)
cat >/etc/v2ray/vCross_v2ray_backup.conf.tmp <<-EOF
# -----------------------------------
# Warning...Please don't modify or delete this file... Thank you!
# Warning...Please don't modify or delete this file... Thank you!
# Warning...Please don't modify or delete this file... Thank you!
# -----------------------------------

# ---- Attention again ----
# Bro...If you see this...Please don't modify or delete this file

# ---- Tips ----
# Hmm...This file is used to backup some files.

# ---- V2Ray transport protocol -----
v2ray_transport=$v2ray_transport

#---- V2Ray port -----
v2ray_port=$v2ray_port

#---- UUID -----
v2ray_id=$uuid

#---- alterId -----
alterId=153

#---- V2Ray dynamic port starting -----
v2ray_dynamicPort_start=$v2ray_dynamicPort_start

#---- V2Ray dynamic port ending -----
v2ray_dynamicPort_end=$v2ray_dynamicPort_end

#---- domain name -----
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
ws_path_status=$is_ws_path

#---- disguising path -----
ws_path=$ws_path

#---- disguising website -----
proxy_site=$proxy_site
		EOF
rm -rf $backup
mv -f /etc/v2ray/vCross_v2ray_backup.conf.tmp /etc/v2ray/vCross_v2ray_backup.conf
echo
echo -e " .... Wow.. .."
echo
echo -e " Please use the command$yellow v2ray reload $none to re-load and config...to avoid unkown issues."
echo
exit 1