[[ -z $ip ]] && get_ip
if [[ $shadowsocks ]]; then
	local ss="ss://$(echo -n "${ssciphers}:${sspass}@${ip}:${ssport}" | base64 -w 0)#vCross_ss_${ip}"
	echo
	echo "---------- Shadowsocks configuration -------------"
	echo
	echo -e "$yellow server addr = $cyan${ip}$none"
	echo
	echo -e "$yellow server port = $cyan$ssport$none"
	echo
	echo -e "$yellow passord = $cyan$sspass$none"
	echo
	echo -e "$yellow encription protocol = $cyan${ssciphers}$none"
	echo
	echo -e "$yellow SS URL = ${cyan}$ss$none"
	echo
	echo -e " Note:$red Shadowsocks Win 4.0.6 $none client maybe can't recoganize this SS URL."
	echo
	echo -e "Tip: Input$cyan v2ray ssqr ${none}to generate Shadowsocks QR code URL"	
	echo
fi
