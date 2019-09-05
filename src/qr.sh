_qr_create() {
	local vmess="vmess://$(cat /etc/v2ray/vmess_qr.json | base64 -w 0)"
	local link="https://whinshine.github.io/qr.html#${vmess}"
	echo
	echo "---------- V2Ray QR code URL, appplied to V2RayNG v0.4.1+ / Kitsunebi -------------"
	echo
	echo -e ${cyan}$link${none}
	echo
	echo
	echo -e "$red Tips: Please check scan result(V2RayNG excluded) $none"
	echo
	echo
	echo " V2Ray Client user guide: https://233v2.com/post/4/"
	echo
	echo
	echo  $link > /etc/v2ray/qr.txt
	echo "please refer to /etc/v2ray/qr.txt"
	rm -rf /etc/v2ray/vmess_qr.json
}
_ss_qr() {
	local ss_link="ss://$(echo -n "${ssciphers}:${sspass}@${ip}:${ssport}" | base64 -w 0)#vCross_ss_${ip}"
	local link="https://whinshine.github.io/qr.html#${ss_link}"
	echo
	echo "---------- Shadowsocks QR code URL -------------"
	echo
	echo -e "$yellow URL = $cyan$link$none"
	echo
	echo -e " Tips...$red Shadowsocks Win 4.0.6 ${none}client maybe can't recoganize this SS URL."
	echo
	echo
}
