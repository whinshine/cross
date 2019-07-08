#!/bin/bash

red='\e[91m'
green='\e[92m'
yellow='\e[93m'
magenta='\e[95m'
cyan='\e[96m'
none='\e[0m'

# Root
[[ $(id -u) != 0 ]] && echo -e " Alas...Please use user ${red}root ${none}to run the script ${yellow}~(^_^) ${none}" && exit 1

_version="v3.13"

cmd="apt-get"

sys_bit=$(uname -m)

case $sys_bit in
i[36]86)
	v2ray_bit="32"
	caddy_arch="386"
	;;
x86_64)
	v2ray_bit="64"
	caddy_arch="amd64"
	;;
*armv6*)
	v2ray_bit="arm"
	caddy_arch="arm6"
	;;
*armv7*)
	v2ray_bit="arm"
	caddy_arch="arm7"
	;;
*aarch64* | *armv8*)
	v2ray_bit="arm64"
	caddy_arch="arm64"
	;;
*)
	echo -e " 
	Haha...This ${red}shit script${none} doesn't support your system ${yellow}(-_-) ${none}

	Note: only Ubuntu 16+ / Debian 8+ / CentOS 7+ supported
	" && exit 1
	;;
esac

if [[ $(command -v yum) ]]; then

	cmd="yum"

fi

backup="/etc/v2ray/vCross_v2ray_backup.conf"

if [[ -f /usr/bin/v2ray/v2ray && -f /etc/v2ray/config.json ]] && [[ -f $backup && -d /etc/v2ray/vCross/v2ray ]]; then

	. $backup

elif [[ -f /usr/bin/v2ray/v2ray && -f /etc/v2ray/config.json ]] && [[ -f /etc/v2ray/vCross_v2ray_backup.txt && -d /etc/v2ray/vCross/v2ray ]]; then

	. /etc/v2ray/vCross/v2ray/tools/v1xx_to_v3xx.sh

else
	echo -e " Alas... ${red}Error occurs...Please re-install V2Ray${none} ${yellow}~(^_^) ${none}" && exit 1
fi

if [[ $mark != "v3" ]]; then
	. /etc/v2ray/vCross/v2ray/tools/v3.sh
fi
if [[ $v2ray_transport -ge 18 ]]; then
	dynamicPort=true
	port_range="${v2ray_dynamicPort_start}-${v2ray_dynamicPort_end}"
fi
if [[ $path_status ]]; then
	is_path=true
fi

uuid=$(cat /proc/sys/kernel/random/uuid)
old_id="e55c8d17-2cf3-b21a-bcf1-eeaccb5aed79"
v2ray_server_config="/etc/v2ray/config.json"
v2ray_client_config="/etc/v2ray/vCross_v2ray_config.json"
v2ray_pid=$(pgrep -f /usr/bin/v2ray/v2ray)
caddy_pid=$(pgrep -f /usr/local/bin/caddy)
_v2ray_sh="/usr/local/sbin/v2ray"
v2ray_ver="$(/usr/bin/v2ray/v2ray -version | head -n 1 | cut -d " " -f2)"
. /etc/v2ray/vCross/v2ray/src/init.sh
systemd=true
# _test=true

if [[ $v2ray_ver != v* ]]; then
	v2ray_ver="v$v2ray_ver"
fi
if [[ ! -f $_v2ray_sh ]]; then
	mv -f /usr/local/bin/v2ray $_v2ray_sh
	chmod +x $_v2ray_sh
	echo -e "\n $yellow Warning: Please re-login SSH too avoid missing v2ray problems.$none  \n" && exit 1
fi

if [ $v2ray_pid ]; then
	v2ray_status="${green}Running$none"
else
	v2ray_status="${red}Not running$none"
fi
if [[ $v2ray_transport == [45] && $caddy ]] && [[ $caddy_pid ]]; then
	caddy_run_status="${green}Running$none"
else
	caddy_run_status="${red}Not running$none"
fi

_load transport.sh
ciphers=(
	aes-128-cfb
	aes-256-cfb
	chacha20
	chacha20-ietf
	aes-128-gcm
	aes-256-gcm
	chacha20-ietf-poly1305
)

get_transport_args() {
	_load v2ray-info.sh
	_v2_args
}
create_vmess_URL_config() {

	[[ -z $net ]] && get_transport_args

	if [[ $v2ray_transport == [45] ]]; then
		cat >/etc/v2ray/vmess_qr.json <<-EOF
		{
			"v": "2",
			"ps": "vCross_${domain}",
			"add": "${domain}",
			"port": "443",
			"id": "${v2ray_id}",
			"aid": "${alterId}",
			"net": "${net}",
			"type": "none",
			"host": "${domain}",
			"path": "$_path",
			"tls": "tls"
		}
		EOF
	else
		[[ -z $ip ]] && get_ip
		cat >/etc/v2ray/vmess_qr.json <<-EOF
		{
			"v": "2",
			"ps": "vCross_${ip}",
			"add": "${ip}",
			"port": "${v2ray_port}",
			"id": "${v2ray_id}",
			"aid": "${alterId}",
			"net": "${net}",
			"type": "${header}",
			"host": "${host}",
			"path": "",
			"tls": ""
		}
		EOF
	fi
}
view_v2ray_config_info() {

	_load v2ray-info.sh
	_v2_args
	_v2_info
}
get_shadowsocks_config() {
	if [[ $shadowsocks ]]; then

		while :; do
			echo
			echo -e "$yellow 1. ${none}View Shadowsocks configuration"
			echo
			echo -e "$yellow 2. ${none}Generate QR code URL"
			echo
			read -p "$(echo -e "Please select [${magenta}1-2$none]:")" _opt
			if [[ -z $_opt ]]; then
				error
			else
				case $_opt in
				1)
					view_shadowsocks_config_info
					break
					;;
				2)
					get_shadowsocks_config_qr_link
					break
					;;
				*)
					error
					;;
				esac
			fi

		done
	else
		shadowsocks_config
	fi
}
view_shadowsocks_config_info() {
	if [[ $shadowsocks ]]; then
		_load ss-info.sh
	else
		shadowsocks_config
	fi
}
get_shadowsocks_config_qr_link() {
	if [[ $shadowsocks ]]; then
		get_ip
		_load qr.sh
		_ss_qr
	else
		shadowsocks_config
	fi

}

get_shadowsocks_config_qr_ask() {
	echo
	while :; do
		echo -e "Generate$yellow Shadowsocks config ${none}QR code URL [${magenta}Y/N$none]"
		read -p "$(echo -e "default [${magenta}N$none]:")" y_n
		[ -z $y_n ] && y_n="n"
		if [[ $y_n == [Yy] ]]; then
			get_shadowsocks_config_qr_link
			break
		elif [[ $y_n == [Nn] ]]; then
			break
		else
			error
		fi
	done

}
change_shadowsocks_config() {
	if [[ $shadowsocks ]]; then

		while :; do
			echo
			echo -e "$yellow 1. $none modify Shadowsocks port"
			echo
			echo -e "$yellow 2. $none modify Shadowsocks passport"
			echo
			echo -e "$yellow 3. $none modify Shadowsocks encription protocol"
			echo
			echo -e "$yellow 4. $none close Shadowsocks"
			echo
			read -p "$(echo -e "Please select [${magenta}1-4$none]:")" _opt
			if [[ -z $_opt ]]; then
				error
			else
				case $_opt in
				1)
					change_shadowsocks_port
					break
					;;
				2)
					change_shadowsocks_password
					break
					;;
				3)
					change_shadowsocks_ciphers
					break
					;;
				4)
					disable_shadowsocks
					break
					;;
				*)
					error
					;;
				esac
			fi

		done
	else

		shadowsocks_config
	fi
}
shadowsocks_config() {
	echo
	echo
	echo -e " $red Dude...You didn't config Shadowsocks $none...Anyway you can config it now if you want...^_^"
	echo
	echo

	while :; do
		echo -e "Config ${yellow}Shadowsocks${none} [${magenta}Y/N$none]"
		read -p "$(echo -e "(default [${cyan}N$none]):") " install_shadowsocks
		[[ -z "$install_shadowsocks" ]] && install_shadowsocks="n"
		if [[ "$install_shadowsocks" == [Yy] ]]; then
			echo
			shadowsocks=true
			shadowsocks_port_config
			shadowsocks_password_config
			shadowsocks_ciphers_config
			pause
			open_port $new_ssport
			backup_config +ss
			ssport=$new_ssport
			sspass=$new_sspass
			ssciphers=$new_ssciphers
			config
			clear
			view_shadowsocks_config_info
			# get_shadowsocks_config_qr_ask
			break
		elif [[ "$install_shadowsocks" == [Nn] ]]; then
			echo
			echo -e " $green Cancel to config Shadowsocks ....$none"
			echo
			break
		else
			error
		fi

	done
}
shadowsocks_port_config() {
	local random=$(shuf -i20001-65535 -n1)
	while :; do
		echo -e "Please input "$yellow"Shadowsocks"$none" port ["$magenta"1-65535"$none"], Can't be same as "$yellow"V2ray"$none" port"
		read -p "$(echo -e "(default port: ${cyan}${random}$none):") " new_ssport
		[ -z "$new_ssport" ] && new_ssport=$random
		case $new_ssport in
		$v2ray_port)
			echo
			echo -e " can't be same as $cyan V2Ray port $none...."
			echo
			echo -e " current V2Ray port: ${cyan}$v2ray_port${none}"
			error
			;;
		[1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
			if [[ $v2ray_transport == [45] ]]; then
				local tls=ture
			fi
			if [[ $tls && $new_ssport == "80" ]] || [[ $tls && $new_ssport == "443" ]]; then
				echo
				echo -e "You have configured "$green"WebSocket + TLS $none or $green HTTP/2"$none"  tranportation protocol."
				echo
				echo -e "So can't choose port "$magenta"80"$none" or "$magenta"443"$none" "
				error
			elif [[ $dynamicPort ]] && [[ $v2ray_dynamicPort_start == $new_ssport || $v2ray_dynamicPort_end == $new_ssport ]]; then
				echo
				echo -e " Sorry, This port conflicts with V2Ray dynamic ports, current V2Ray dynamic port scrope: ${cyan}$port_range${none}"
				error
			elif [[ $dynamicPort ]] && [[ $v2ray_dynamicPort_start -lt $new_ssport && $new_ssport -le $v2ray_dynamicPort_end ]]; then
				echo
				echo -e " Sorry, This port conflicts with V2Ray dynamic ports, current V2Ray dynamic port scrope: ${cyan}$port_range${none}"
				error
			elif [[ $socks && $new_ssport == $socks_port ]]; then
				echo
				echo -e "Sorry, This port conflicts with Socks port...current Socks port: ${cyan}$socks_port$none"
				error
			elif [[ $mtproto && $new_ssport == $mtproto_port ]]; then
				echo
				echo -e "Sorry, This port conflicts with MTProto port...current MTProto port: ${cyan}$mtproto_port$none"
				error
			else
				echo
				echo
				echo -e "$yellow Shadowsocks port = $cyan$new_ssport$none"
				echo "----------------------------------------------------------------"
				echo
				break
			fi
			;;
		*)
			error
			;;
		esac

	done

}

shadowsocks_password_config() {

	while :; do
		echo -e "Please input "$yellow"Shadowsocks"$none" password"
		read -p "$(echo -e "(default password: ${cyan}vCross_Dane$none)"): " new_sspass
		[ -z "$new_sspass" ] && new_sspass="vCross_Dane"
		case $new_sspass in
		*[/$]*)
			echo
			echo -e " This script is shit..So password can't include $red / $none or $red $ $none.... "
			echo
			error
			;;
		*)
			echo
			echo
			echo -e "$yellow Shadowsocks password = $cyan$new_sspass$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		esac

	done

}

shadowsocks_ciphers_config() {

	while :; do
		echo -e "Please select "$yellow"Shadowsocks"$none" encription protocol [${magenta}1-7$none]"
		for ((i = 1; i <= ${#ciphers[*]}; i++)); do
			ciphers_show="${ciphers[$i - 1]}"
			echo
			echo -e "$yellow $i. $none${ciphers_show}"
		done
		echo
		read -p "$(echo -e "(default encription protocol: ${cyan}${ciphers[6]}$none)"):" ssciphers_opt
		[ -z "$ssciphers_opt" ] && ssciphers_opt=7
		case $ssciphers_opt in
		[1-7])
			new_ssciphers=${ciphers[$ssciphers_opt - 1]}
			echo
			echo
			echo -e "$yellow Shadowsocks encription protocol = $cyan${new_ssciphers}$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		*)
			error
			;;
		esac

	done
}

change_shadowsocks_port() {
	echo
	while :; do
		echo -e "Please input "$yellow"Shadowsocks"$none" port ["$magenta"1-65535"$none"]"
		read -p "$(echo -e "(Current port: ${cyan}$ssport$none):") " new_ssport
		[ -z "$new_ssport" ] && error && continue
		case $new_ssport in
		$ssport)
			echo
			echo " same as current port....no need to modify"
			error
			;;
		$v2ray_port)
			echo
			echo -e " can't be same with $cyan V2Ray port $none...."
			error
			;;
		[1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
			if [[ $v2ray_transport == [45] ]]; then
				local tls=ture
			fi
			if [[ $tls && $new_ssport == "80" ]] || [[ $tls && $new_ssport == "443" ]]; then
				echo
				echo -e "You have chosen "$green"WebSocket + TLS $none or $green HTTP/2"$none" protocol."
				echo
				echo -e "So can't choose  "$magenta"80"$none" or "$magenta"443"$none" "
				error
			elif [[ $dynamicPort ]] && [[ $v2ray_dynamicPort_start == $new_ssport || $v2ray_dynamicPort_end == $new_ssport ]]; then
				echo
				echo -e " Sorry. This port conflicts with V2Ray dynamic ports. Current V2Ray dynamic port scope: ${cyan}$port_range${none}"
				error
			elif [[ $dynamicPort ]] && [[ $v2ray_dynamicPort_start -lt $new_ssport && $new_ssport -le $v2ray_dynamicPort_end ]]; then
				echo
				echo -e " Sorry. This port conflicts with V2Ray dynamic ports. Current V2Ray dynamic port scope: ${cyan}$port_range${none}"
				error
			elif [[ $socks && $new_ssport == $socks_port ]]; then
				echo
				echo -e "Sorry. This port conflicts with Socks port...Current Socks port: ${cyan}$socks_port$none"
				error
			elif [[ $mtproto && $new_ssport == $mtproto_port ]]; then
				echo
				echo -e "Sorry. This port conflicts with MTProto port...Current MTProto port: ${cyan}$mtproto_port$none"
				error
			else
				echo
				echo
				echo -e "$yellow Shadowsocks port = $cyan$new_ssport$none"
				echo "----------------------------------------------------------------"
				echo
				pause
				backup_config ssport
				del_port $ssport
				open_port $new_ssport
				ssport=$new_ssport
				config
				clear
				view_shadowsocks_config_info
				# get_shadowsocks_config_qr_ask
				break
			fi
			;;
		*)
			error
			;;
		esac

	done
}
change_shadowsocks_password() {
	echo
	while :; do
		echo -e "Please input "$yellow"Shadowsocks"$none" password"
		read -p "$(echo -e "(current password: ${cyan}$sspass$none)"): " new_sspass
		[ -z "$new_sspass" ] && error && continue
		case $new_sspass in
		$sspass)
			echo
			echo " same as current password....no need to modify"
			error
			;;
		*[/$]*)
			echo
			echo -e " This scrip is shit..So password can't include $red / $none or $red $ $none.... "
			echo
			error
			;;
		*)
			echo
			echo
			echo -e "$yellow Shadowsocks password = $cyan$new_sspass$none"
			echo "----------------------------------------------------------------"
			echo
			pause
			backup_config sspass
			sspass=$new_sspass
			config
			clear
			view_shadowsocks_config_info
			# get_shadowsocks_config_qr_ask
			break
			;;
		esac

	done

}

change_shadowsocks_ciphers() {
	echo
	while :; do
		echo -e "Please select "$yellow"Shadowsocks"$none" encription protocol [${magenta}1-${#ciphers[*]}$none]"
		for ((i = 1; i <= ${#ciphers[*]}; i++)); do
			ciphers_show="${ciphers[$i - 1]}"
			echo
			echo -e "$yellow $i. $none${ciphers_show}"
		done
		echo
		read -p "$(echo -e "(current encription protocol: ${cyan}${ssciphers}$none)"):" ssciphers_opt
		[ -z "$ssciphers_opt" ] && error && continue
		case $ssciphers_opt in
		[1-7])
			new_ssciphers=${ciphers[$ssciphers_opt - 1]}
			if [[ $new_ssciphers == $ssciphers ]]; then
				echo
				echo " same as current encription protocol....no need to modify"
				error && continue
			fi
			echo
			echo
			echo -e "$yellow Shadowsocks encription protocol = $cyan${new_ssciphers}$none"
			echo "----------------------------------------------------------------"
			echo
			pause
			backup_config ssciphers
			ssciphers=$new_ssciphers
			config
			clear
			view_shadowsocks_config_info
			# get_shadowsocks_config_qr_ask
			break
			;;
		*)
			error
			;;
		esac

	done

}
disable_shadowsocks() {
	echo

	while :; do
		echo -e "close ${yellow}Shadowsocks${none} [${magenta}Y/N$none]"
		read -p "$(echo -e "(default [${cyan}N$none]):") " y_n
		[[ -z "$y_n" ]] && y_n="n"
		if [[ "$y_n" == [Yy] ]]; then
			echo
			echo
			echo -e "$yellow close Shadowsocks = $cyan Yes $none"
			echo "----------------------------------------------------------------"
			echo
			pause
			backup_config -ss
			del_port $ssport
			shadowsocks=''
			config
			# clear
			echo
			echo
			echo
			echo -e "$green Shadowsocks has been closed...$none"
			echo
			break
		elif [[ "$y_n" == [Nn] ]]; then
			echo
			echo -e " $green cancel to close Shadowsocks ....$none"
			echo
			break
		else
			error
		fi

	done
}
change_v2ray_config() {
	local _menu=(
		"modify V2Ray port"
		"modify V2Ray tranportation protocol"
		"modify V2Ray dynamic port (if possible)"
		"modify user ID ( UUID )"
		"modify TLS domain (if possible)"
		"modify diffluence path (if possible)"
		"modify disguiseing website(if possible)"
		"turn off website disguising and diffluence (if possible)"
		"turn on / turn off Ad blocking"
	)
	while :; do
		for ((i = 1; i <= ${#_menu[*]}; i++)); do
			if [[ "$i" -le 9 ]]; then
				echo
				echo -e "$yellow  $i. $none${_menu[$i - 1]}"
			else
				echo
				echo -e "$yellow $i. $none${_menu[$i - 1]}"
			fi
		done
		echo
		read -p "$(echo -e "Please choose [${magenta}1-${#_menu[*]}$none]:")" _opt
		if [[ -z $_opt ]]; then
			error
		else
			case $_opt in
			1)
				change_v2ray_port
				break
				;;
			2)
				change_v2ray_transport
				break
				;;
			3)
				change_v2ray_dynamicport
				break
				;;
			4)
				change_v2ray_id
				break
				;;
			5)
				change_domain
				break
				;;
			6)
				change_path_config
				break
				;;
			7)
				change_proxy_site_config
				break
				;;
			8)
				disable_path
				break
				;;
			9)
				blocked_hosts
				break
				;;
			[aA][Ii][aA][Ii] | [Dd][Dd])
				custom_uuid
				break
				;;
			[Dd] | [Aa][Ii] | 153 | 153[Bb][Ll][Oo][Gg] | 153[Bb][Ll][Oo][Gg].[Cc][Oo][Mm] | 153[Bb][Oo][Yy] | [Aa][Ll][Tt][Ee][Rr][Ii][Dd])
				change_v2ray_alterId
				break
				;;
			*)
				error
				;;
			esac
		fi
	done
}
change_v2ray_port() {
	if [[ $v2ray_transport == 4 ]]; then
		echo
		echo -e " Currently you use $yellow WebSocket + TLS $none...So it makes no difference to modify V2Ray port"
		echo
		echo " If you want to use another port, you can firstly modify tranportation protocol..and then modify V2Ray port"
		echo
		change_v2ray_transport_ask
	elif [[ $v2ray_transport == 5 ]]; then
		echo
		echo -e " Currently you use $yellow HTTP/2 $none...So it makes no difference to modify V2Ray port"
		echo
		echo " If you want to use another port, you can firstly modify tranportation protocol..and then modify V2Ray port"
		echo
		change_v2ray_transport_ask
	else
		echo
		while :; do
			echo -e "Please input "$yellow"V2Ray"$none" port ["$magenta"1-65535"$none"]"
			read -p "$(echo -e "(current port: ${cyan}${v2ray_port}$none):")" v2ray_port_opt
			[[ -z $v2ray_port_opt ]] && error && continue
			case $v2ray_port_opt in
			$v2ray_port)
				echo
				echo " Alas...same as current port...no need to modify"
				error
				;;
			[1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
				if [[ $dynamicPort ]] && [[ $v2ray_dynamicPort_start == $v2ray_port_opt || $v2ray_dynamicPort_end == $v2ray_port_opt ]]; then
					echo
					echo -e " Sorry. This port conflicts with V2Ray dynamic ports. Current V2Ray dynamic port scope: ${cyan}$port_range${none}"
					error
				elif [[ $dynamicPort ]] && [[ $v2ray_dynamicPort_start -lt $v2ray_port_opt && $v2ray_port_opt -le $v2ray_dynamicPort_end ]]; then
					echo
					echo -e " Sorry. This port conflicts with V2Ray dynamic ports. Current V2Ray dynamic port scope: ${cyan}$port_range${none}"
					error
				elif [[ $shadowsocks && $v2ray_port_opt == $ssport ]]; then
					echo
					echo -e "Sorry, This port conflicts with Shadowsocks port...current Shadowsocks port: ${cyan}$ssport$none"
					error
				elif [[ $socks && $v2ray_port_opt == $socks_port ]]; then
					echo
					echo -e "Sorry, This port conflicts with Socks port...current Socks port: ${cyan}$socks_port$none"
					error
				elif [[ $mtproto && $v2ray_port_opt == $mtproto_port ]]; then
					echo
					echo -e "Sorry, This port conflicts with MTProto port...current MTProto port: ${cyan}$mtproto_port$none"
					error
				else
					echo
					echo
					echo -e "$yellow V2Ray port = $cyan$v2ray_port_opt$none"
					echo "----------------------------------------------------------------"
					echo
					pause
					backup_config v2ray_port
					del_port $v2ray_port
					open_port $v2ray_port_opt
					v2ray_port=$v2ray_port_opt
					config
					clear
					view_v2ray_config_info
					# download_v2ray_config_ask
					break
				fi
				;;
			*)
				error
				;;
			esac

		done
	fi

}
download_v2ray_config_ask() {
	echo
	while :; do
		echo -e "Need to downlod V2Ray config / generate config URL / generate QR code URL [${magenta}Y/N$none]"
		read -p "$(echo -e "default [${cyan}N$none]:")" y_n
		[ -z $y_n ] && y_n="n"
		if [[ $y_n == [Yy] ]]; then
			download_v2ray_config
			break
		elif [[ $y_n == [Nn] ]]; then
			break
		else
			error
		fi
	done

}
change_v2ray_transport_ask() {
	echo
	while :; do
		echo -e "Need to $yellow V2Ray $none tranportation protocol [${magenta}Y/N$none]"
		read -p "$(echo -e "default [${cyan}N$none]:")" y_n
		[ -z $y_n ] && break
		if [[ $y_n == [Yy] ]]; then
			change_v2ray_transport
			break
		elif [[ $y_n == [Nn] ]]; then
			break
		else
			error
		fi
	done
}
change_v2ray_transport() {
	echo
	while :; do
		echo -e "Please choose "$yellow"V2Ray"$none" protocol [${magenta}1-${#transport[*]}$none]"
		echo
		for ((i = 1; i <= ${#transport[*]}; i++)); do
			Stream="${transport[$i - 1]}"
			if [[ "$i" -le 9 ]]; then
				# echo
				echo -e "$yellow  $i. $none${Stream}"
			else
				# echo
				echo -e "$yellow $i. $none${Stream}"
			fi
		done
		echo
		echo "Note1: the items containing [dynamicPort] will enable dynamic ports.."
		echo "Note2: [utp | srtp | wechat-video | dtls | wireguard] will be disguised as [BT | video talking | wechat video | DTLS 1.2 data diagram | WireGuard datagram] respectively."
		echo
		read -p "$(echo -e "(current tranportation protocol: ${cyan}${transport[$v2ray_transport - 1]}$none)"):" v2ray_transport_opt
		if [ -z "$v2ray_transport_opt" ]; then
			error
		else
			case $v2ray_transport_opt in
			$v2ray_transport)
				echo
				echo " Alas...same as current protocol...no need to modify"
				error
				;;
			4 | 5)
				if [[ $v2ray_port == "80" || $v2ray_port == "443" ]]; then
					echo
					echo -e " Sorry...If you wanna use ${cyan} ${transport[$v2ray_transport_opt - 1]} $none.. ${red}V2Ray port can't be 80 or 443 ...$none"
					echo
					echo -e " current V2Ray port: ${cyan}$v2ray_port$none"
					error
				elif [[ $shadowsocks ]] && [[ $ssport == "80" || $ssport == "443" ]]; then
					echo
					echo -e " Sorry...If you wanna use ${cyan} ${transport[$v2ray_transport_opt - 1]} $none.. ${red}Shadowsocks port can't be 80 or 443 ...$none"
					echo
					echo -e " current Shadowsocks port: ${cyan}$ssport$none"
					error
				elif [[ $socks ]] && [[ $socks_port == "80" || $socks_port == "443" ]]; then
					echo
					echo -e " Sorry...If you wanna use ${cyan} ${transport[$v2ray_transport_opt - 1]} $none.. ${red}Socks port can't be 80 or 443 ...$none"
					echo
					echo -e " current Socks port: ${cyan}$socks_port$none"
					error
				elif [[ $mtproto ]] && [[ $mtproto_port == "80" || $mtproto_port == "443" ]]; then
					echo
					echo -e " Sorry...If you wanna use${cyan} ${transport[$v2ray_transport_opt - 1]} $none.. ${red}MTProto port can't be 80 or 443 ...$none"
					echo
					echo -e " current MTProto port: ${cyan}$mtproto_port$none"
					error
				else
					echo
					echo
					echo -e "$yellow V2Ray tranportation protocol = $cyan${transport[$v2ray_transport_opt - 1]}$none"
					echo "----------------------------------------------------------------"
					echo
					break
				fi
				;;
			[1-9] | [1-2][0-9] | 3[0-2])
				echo
				echo
				echo -e "$yellow V2Ray tranportation protocol = $cyan${transport[$v2ray_transport_opt - 1]}$none"
				echo "----------------------------------------------------------------"
				echo
				break
				;;
			*)
				error
				;;
			esac
		fi

	done
	pause

	if [[ $v2ray_transport_opt == [45] ]]; then
		tls_config
	elif [[ $v2ray_transport_opt -ge 18 ]]; then
		v2ray_dynamic_port_start
		v2ray_dynamic_port_end
		pause
		old_transport
		open_port "multiport"
		backup_config v2ray_transport v2ray_dynamicPort_start v2ray_dynamicPort_end
		port_range="${v2ray_dynamic_port_start_input}-${v2ray_dynamic_port_end_input}"
		v2ray_transport=$v2ray_transport_opt
		config
		clear
		view_v2ray_config_info
		# download_v2ray_config_ask
	else
		old_transport
		backup_config v2ray_transport
		v2ray_transport=$v2ray_transport_opt
		config
		clear
		view_v2ray_config_info
		# download_v2ray_config_ask
	fi

}
old_transport() {
	if [[ $v2ray_transport == [45] ]]; then
		del_port "80"
		del_port "443"
		if [[ $caddy && $caddy_pid ]]; then
			do_service stop caddy
			if [[ $systemd ]]; then
				systemctl disable caddy >/dev/null 2>&1
			else
				update-rc.d -f caddy remove >/dev/null 2>&1
			fi
		elif [[ $caddy ]]; then
			if [[ $systemd ]]; then
				systemctl disable caddy >/dev/null 2>&1
			else
				update-rc.d -f caddy remove >/dev/null 2>&1
			fi
		fi
		if [[ $is_path ]]; then
			backup_config -path
		fi
	elif [[ $v2ray_transport -ge 18 ]]; then
		del_port "multiport"
	fi
}

tls_config() {
	while :; do
		echo
		echo
		echo
		echo -e "Please input a valid domain name $magenta valid domain name$none MUST be valid!"
		read -p "(for example: heidark.ga): " new_domain
		[ -z "$new_domain" ] && error && continue
		echo
		echo
		echo -e "$yellow your domain name = $cyan$new_domain$none"
		echo "----------------------------------------------------------------"
		break
	done
	get_ip
	echo
	echo
	echo -e "$yellow Please associated $magenta $domain $none $yellow with: $cyan $ip $none"
	echo
	echo -e "$yellow Please associated $magenta $domain $none $yellow with: $cyan $ip $none"
	echo
	echo -e "$yellow Please associated $magenta $domain $none $yellow with: $cyan $ip $none"
	echo "----------------------------------------------------------------"
	echo

	while :; do

		read -p "$(echo -e "(The domain name has corrected associated?: [${magenta}Y$none]):") " record
		if [[ -z "$record" ]]; then
			error
		else
			if [[ "$record" == [Yy] ]]; then
				domain_check
				echo
				echo
				echo -e "$yellow Domain name Resolution = ${cyan}I'm sure it has been resolved.$none"
				echo "----------------------------------------------------------------"
				echo
				break
			else
				error
			fi
		fi

	done

	if [[ $caddy ]]; then
		path_config_ask
		pause
		# domain_check
		backup_config v2ray_transport domain
		if [[ $new_path ]]; then
			backup_config +path
			path=$new_path
			proxy_site=$new_proxy_site
			is_path=true
		fi

		if [[ $v2ray_transport -ge 18 ]]; then
			del_port "multiport"
		fi
		domain=$new_domain

		open_port "80"
		open_port "443"
		if [[ $systemd ]]; then
			systemctl enable caddy >/dev/null 2>&1
		else
			update-rc.d -f caddy defaults >/dev/null 2>&1
		fi
		v2ray_transport=$v2ray_transport_opt
		caddy_config
		config
		clear
		view_v2ray_config_info
		# download_v2ray_config_ask
	else
		if [[ $v2ray_transport_opt == 5 ]]; then
			path_config_ask
			pause
			domain_check
			backup_config v2ray_transport domain caddy
			if [[ $new_path ]]; then
				backup_config +path
				path=$new_path
				proxy_site=$new_proxy_site
				is_path=true
			fi
			if [[ $v2ray_transport -ge 18 ]]; then
				del_port "multiport"
			fi
			domain=$new_domain
			install_caddy
			open_port "80"
			open_port "443"
			v2ray_transport=$v2ray_transport_opt
			caddy_config
			config
			caddy=true
			clear
			view_v2ray_config_info
			# download_v2ray_config_ask
		else
			auto_tls_config
		fi
	fi

}
auto_tls_config() {
	echo -e "

		Installing Caddy to config TLS automatically.
		
		If you have installed Nginx or Caddy

		$yellow and ..have configured TLS yourself, $none

		you need not turn on 'config TTL automatically'.
		"
	echo "----------------------------------------------------------------"
	echo

	while :; do

		read -p "$(echo -e "(config TLS automatically: [${magenta}Y/N$none]):") " auto_install_caddy
		if [[ -z "$auto_install_caddy" ]]; then
			error
		else
			if [[ "$auto_install_caddy" == [Yy] ]]; then
				echo
				echo
				echo -e "$yellow config TLS automatically = $cyan turn on$none"
				echo "----------------------------------------------------------------"
				echo
				path_config_ask
				pause
				domain_check
				backup_config v2ray_transport domain caddy
				if [[ $new_path ]]; then
					backup_config +path
					path=$new_path
					proxy_site=$new_proxy_site
					is_path=true
				fi
				if [[ $v2ray_transport -ge 18 ]]; then
					del_port "multiport"
				fi
				domain=$new_domain
				install_caddy
				open_port "80"
				open_port "443"
				v2ray_transport=$v2ray_transport_opt
				caddy_config
				config
				caddy=true
				clear
				view_v2ray_config_info
				# download_v2ray_config_ask
				break
			elif [[ "$auto_install_caddy" == [Nn] ]]; then
				echo
				echo
				echo -e "$yellow config TLS automatically = $cyan turn off$none"
				echo "----------------------------------------------------------------"
				echo
				pause
				domain_check
				backup_config v2ray_transport domain
				if [[ $v2ray_transport -ge 18 ]]; then
					del_port "multiport"
				fi
				domain=$new_domain
				open_port "80"
				open_port "443"
				v2ray_transport=$v2ray_transport_opt
				config
				clear
				view_v2ray_config_info
				# download_v2ray_config_ask
				break
			else
				error
			fi
		fi

	done
}

path_config_ask() {
	echo
	while :; do
		echo -e "Turn on website disguise and diffluence? [${magenta}Y/N$none]"
		read -p "$(echo -e "(default: [${cyan}N$none]):")" path_ask
		[[ -z $path_ask ]] && path_ask="n"

		case $path_ask in
		Y | y)
			path_config
			break
			;;
		N | n)
			echo
			echo
			echo -e "$yellow website disguise and diffluence = $cyan turn off$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		*)
			error
			;;
		esac
	done
}
path_config() {
	echo
	while :; do
		echo -e "Please input the ${magenta} diffluence path $none , for example /beowulf , only beowulf need to input"
		read -p "$(echo -e "(default: [${cyan}beowulf$none]):")" new_path
		[[ -z $new_path ]] && new_path="beowulf"

		case $new_path in
		*[/$]*)
			echo
			echo -e " This script is a shit. So the diffluence path can't include $red / ${none}or$red $ $none.... "
			echo
			error
			;;
		*)
			echo
			echo
			echo -e "$yellow diffluence path = ${cyan}/${new_path}$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		esac
	done
	proxy_site_config
}
proxy_site_config() {
	echo
	while :; do
		echo -e "Please input ${magenta} a normal $none ${cyan}URL$none to act as  ${cyan}website disguise$none , for example https://outlook.live.com/owa/"
		echo -e "For example...Your current domain name is  $green $domain$none , the disguising URL will be https://outlook.live.com/owa/"
		echo -e "And when you open your domain name ...the content from https://outlook.live.com/owa/ will be shown."
		echo -e "Actually a reverse proxy...it's OK..."
		echo -e "If fail to disguise...you can modify v2ray config to disguise"
		read -p "$(echo -e "(default: [${cyan}https://outlook.live.com/owa/$none]):")" new_proxy_site
		[[ -z $new_proxy_site ]] && new_proxy_site="https://outlook.live.com/owa/"

		case $new_proxy_site in
		*[#$]*)
			echo
			echo -e " This scrip is a shit..So the disguiseing URL can't include $red # ${none}or$red $ $none.... "
			echo
			error
			;;
		*)
			echo
			echo
			echo -e "$yellow disguising URL = ${cyan}${new_proxy_site}$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		esac
	done
}

install_caddy() {
	_load download-caddy.sh
	_download_caddy_file
	_install_caddy_service

}
caddy_config() {
	# local email=$(shuf -i1-10000000000 -n1)
	_load caddy-config.sh
	# systemctl restart caddy
	do_service restart caddy
}
v2ray_dynamic_port_start() {
	echo
	echo
	while :; do
		echo -e "Please input "$yellow"V2Ray dynamic port starting "$none"scrope ["$magenta"1-65535"$none"]"
		read -p "$(echo -e "(default staring: ${cyan}10000$none):")" v2ray_dynamic_port_start_input
		[ -z $v2ray_dynamic_port_start_input ] && v2ray_dynamic_port_start_input=10000
		case $v2ray_dynamic_port_start_input in
		$v2ray_port)
			echo
			echo " Can't be same with V2Ray port...."
			echo
			echo -e " Current V2Ray port:${cyan}$v2ray_port${none}"
			error
			;;
		[1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
			if [[ $shadowsocks && $v2ray_dynamic_port_start_input == $ssport ]]; then
				echo
				echo -e "Sorry, this port conflicts with Shadowsocks port...current Shadowsocks port: ${cyan}$ssport$none"
				error
			elif [[ $socks && $v2ray_dynamic_port_start_input == $socks_port ]]; then
				echo
				echo -e "Sorry, this port conflicts with Socks port...current Socks port: ${cyan}$socks_port$none"
				error
			elif [[ $mtproto && $v2ray_dynamic_port_start_input == $mtproto_port ]]; then
				echo
				echo -e "Sorry, this port conflicts with MTProto port...current MTProto port: ${cyan}$mtproto_port$none"
				error
			else
				echo
				echo
				echo -e "$yellow V2Ray dynamic port staring = $cyan$v2ray_dynamic_port_start_input$none"
				echo "----------------------------------------------------------------"
				echo
				break
			fi

			;;
		*)
			error
			;;
		esac

	done

	if [[ $v2ray_dynamic_port_start_input -lt $v2ray_port ]]; then
		lt_v2ray_port=true
	fi
	if [[ $shadowsocks ]] && [[ $v2ray_dynamic_port_start_input -lt $ssport ]]; then
		lt_ssport=true
	fi
	if [[ $socks ]] && [[ $v2ray_dynamic_port_start_input -lt $socks_port ]]; then
		lt_socks_port=true
	fi
	if [[ $mtproto ]] && [[ $v2ray_dynamic_port_start_input -lt $mtproto_port ]]; then
		lt_mtproto_port=true
	fi

}

v2ray_dynamic_port_end() {
	echo
	while :; do
		echo -e "Please input "$yellow"V2Ray dynamic port ending "$none"scope ["$magenta"1-65535"$none"]"
		read -p "$(echo -e "(default ending: ${cyan}20000$none):")" v2ray_dynamic_port_end_input
		[ -z $v2ray_dynamic_port_end_input ] && v2ray_dynamic_port_end_input=20000
		case $v2ray_dynamic_port_end_input in
		[1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])

			if [[ $v2ray_dynamic_port_end_input -le $v2ray_dynamic_port_start_input ]]; then
				echo
				echo " can't be less than or equal to staring"
				echo
				echo -e " current V2Ray dynamic port starting: ${cyan}$v2ray_dynamic_port_start_input${none}"
				error
			elif [ $lt_v2ray_port ] && [[ ${v2ray_dynamic_port_end_input} -ge $v2ray_port ]]; then
				echo
				echo " V2Ray dynamic port ending can't include V2Ray port..."
				echo
				echo -e " current V2Ray port: ${cyan}$v2ray_port$none"
				error
			elif [ $lt_ssport ] && [[ ${v2ray_dynamic_port_end_input} -ge $ssport ]]; then
				echo
				echo " V2Ray dynamic ports ending can't include Shadowsocks port..."
				echo
				echo -e " current Shadowsocks port: ${cyan}$ssport$none"
				error
			elif [ $lt_socks_port ] && [[ ${v2ray_dynamic_port_end_input} -ge $socks_port ]]; then
				echo
				echo " V2Ray dynamic ports ending can't include Socks port..."
				echo
				echo -e " current Socks port: ${cyan}$socks_port$none"
				error
			elif [ $lt_mtproto_port ] && [[ ${v2ray_dynamic_port_end_input} -ge $mtproto_port ]]; then
				echo
				echo " V2Ray dynamic ports ending can't include MTProto port..."
				echo
				echo -e " current MTProto port: ${cyan}$mtproto_port$none"
				error
			else
				echo
				echo
				echo -e "$yellow V2Ray dynamic ports ending = $cyan$v2ray_dynamic_port_end_input$none"
				echo "----------------------------------------------------------------"
				echo
				break
			fi
			;;
		*)
			error
			;;
		esac

	done

}
change_v2ray_dynamicport() {
	if [[ $v2ray_transport -ge 18 ]]; then
		change_v2ray_dynamic_port_start
		change_v2ray_dynamic_port_end
		pause
		del_port "multiport"
		open_port "multiport"
		backup_config v2ray_dynamicPort_start v2ray_dynamicPort_end
		port_range="${v2ray_dynamic_port_start_input}-${v2ray_dynamic_port_end_input}"
		config
		# clear
		echo
		echo -e "$green success to modify V2Ray dynamic ports...no need to modify V2Ray client config...remain them there...$none"
		echo
	else
		echo
		echo -e "$red ...current tranportation protocol doesn't turn on dynamic ports...$none"
		echo
		while :; do
			echo -e "Need to modify tranportation protocol [${magenta}Y/N$none]"
			read -p "$(echo -e "default [${cyan}N$none]:")" y_n
			if [[ -z $y_n ]]; then
				echo
				echo -e "$green cancel to modify tranportation protocol...$none"
				echo
				break
			else
				if [[ $y_n == [Yy] ]]; then
					change_v2ray_transport
					break
				elif [[ $y_n == [Nn] ]]; then
					echo
					echo -e "$green cancel to modify tranportation protocol...$none"
					echo
					break
				else
					error
				fi
			fi
		done

	fi
}
change_v2ray_dynamic_port_start() {
	echo
	echo
	while :; do
		echo -e "Please input "$yellow"V2Ray dynamic port staring "$none"scope ["$magenta"1-65535"$none"]"
		read -p "$(echo -e "(current staring: ${cyan}$v2ray_dynamicPort_start$none):")" v2ray_dynamic_port_start_input
		[ -z $v2ray_dynamic_port_start_input ] && error && continue
		case $v2ray_dynamic_port_start_input in
		$v2ray_port)
			echo
			echo " can't be same as V2Ray port...."
			echo
			echo -e " current V2Ray port: ${cyan}$v2ray_port${none}"
			error
			;;
		[1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
			if [[ $shadowsocks && $v2ray_dynamic_port_start_input == $ssport ]]; then
				echo
				echo -e "Sorry, this port conflicts with Shadowsocks port...current Shadowsocks port: ${cyan}$ssport$none"
				error
			elif [[ $socks && $v2ray_dynamic_port_start_input == $socks_port ]]; then
				echo
				echo -e "Sorry, this port conflicts with Socks port...current Socks port: ${cyan}$socks_port$none"
				error
			elif [[ $mtproto && $v2ray_dynamic_port_start_input == $mtproto_port ]]; then
				echo
				echo -e "Sorry, this port conflicts with MTProto port...current MTProto port: ${cyan}$mtproto_port$none"
				error
			else
				echo
				echo
				echo -e "$yellow V2Ray dynamic port staring = $cyan$v2ray_dynamic_port_start_input$none"
				echo "----------------------------------------------------------------"
				echo
				break
			fi

			;;
		*)
			error
			;;
		esac

	done

	if [[ $v2ray_dynamic_port_start_input -lt $v2ray_port ]]; then
		lt_v2ray_port=true
	fi
	if [[ $shadowsocks ]] && [[ $v2ray_dynamic_port_start_input -lt $ssport ]]; then
		lt_ssport=true
	fi
	if [[ $socks ]] && [[ $v2ray_dynamic_port_start_input -lt $socks_port ]]; then
		lt_socks_port=true
	fi
	if [[ $mtproto ]] && [[ $v2ray_dynamic_port_start_input -lt $mtproto_port ]]; then
		lt_mtproto_port=true
	fi
}

change_v2ray_dynamic_port_end() {
	echo
	while :; do
		echo -e "Please input "$yellow"V2Ray dynamic port ending "$none"scope ["$magenta"1-65535"$none"]"
		read -p "$(echo -e "(current ending: ${cyan}$v2ray_dynamicPort_end$none):")" v2ray_dynamic_port_end_input
		[ -z $v2ray_dynamic_port_end_input ] && error && continue
		case $v2ray_dynamic_port_end_input in
		[1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])

			if [[ $v2ray_dynamic_port_end_input -le $v2ray_dynamic_port_start_input ]]; then
				echo
				echo " Can't be less than or equal to V2Ray staring"
				echo
				echo -e " current V2Ray staring${cyan}$v2ray_dynamic_port_start_input${none}"
				error
			elif [ $lt_v2ray_port ] && [[ ${v2ray_dynamic_port_end_input} -ge $v2ray_port ]]; then
				echo
				echo " V2Ray dynamic port ending can't include V2Ray port..."
				echo
				echo -e " current V2Ray port: ${cyan}$v2ray_port$none"
				error
			elif [ $lt_ssport ] && [[ ${v2ray_dynamic_port_end_input} -ge $ssport ]]; then
				echo
				echo " V2Ray dynamic port ending can't include Shadowsocks port..."
				echo
				echo -e " current Shadowsocks port: ${cyan}$ssport$none"
				error
			elif [ $lt_socks_port ] && [[ ${v2ray_dynamic_port_end_input} -ge $socks_port ]]; then
				echo
				echo " V2Ray dynamic port ending can't include Socks port..."
				echo
				echo -e " current Socks port: ${cyan}$socks_port$none"
				error
			elif [ $lt_mtproto_port ] && [[ ${v2ray_dynamic_port_end_input} -ge $mtproto_port ]]; then
				echo
				echo "V2Ray dynamic port ending can't include MTProto port..."
				echo
				echo -e " current MTProto port: ${cyan}$mtproto_port$none"
				error
			else
				echo
				echo
				echo -e "$yellow V2Ray dynamic port ending = $cyan$v2ray_dynamic_port_end_input$none"
				echo "----------------------------------------------------------------"
				echo
				break
			fi
			;;
		*)
			error
			;;
		esac

	done

}
change_v2ray_id() {
	echo
	while :; do
		echo -e "need to modify user ID [${magenta}Y/N$none]"
		read -p "$(echo -e "default [${cyan}N$none]:")" y_n
		if [[ -z $y_n ]]; then
			echo
			echo -e "$green cancel to modify user ID...$none"
			echo
			break
		else
			if [[ $y_n == [Yy] ]]; then
				echo
				echo
				echo -e "$yellow modify user ID = $cyan sure$none"
				echo "----------------------------------------------------------------"
				echo
				pause
				backup_config uuid
				v2ray_id=$uuid
				config
				clear
				view_v2ray_config_info
				# download_v2ray_config_ask
				break
			elif [[ $y_n == [Nn] ]]; then
				echo
				echo -e "$green cancel to modify user ID...$none"
				echo
				break
			else
				error
			fi
		fi
	done
}
change_domain() {
	if [[ $v2ray_transport == [45] ]] && [[ $caddy ]]; then
		while :; do
			echo
			echo -e "Please input a $magenta valid domain name$none, MUST be valid!"
			read -p "$(echo -e "(current domain name: ${cyan}$domain$none):") " new_domain
			[ -z "$new_domain" ] && error && continue
			if [[ $new_domain == $domain ]]; then
				echo
				echo -e " same as current domain name... no need to modify"
				echo
				error && continue
			fi
			echo
			echo
			echo -e "$yellow your domain name = $cyan$new_domain$none"
			echo "----------------------------------------------------------------"
			break
		done
		get_ip
		echo
		echo
		echo -e "$yellow Please associated $magenta $domain $none $yellow with: $cyan $ip $none"
		echo
		echo -e "$yellow Please associated $magenta $domain $none $yellow with: $cyan $ip $none"
		echo
		echo -e "$yellow Please associated $magenta $domain $none $yellow with: $cyan $ip $none"
		echo "----------------------------------------------------------------"
		echo

		while :; do

			read -p "$(echo -e "(The domain name has corrected associated?: [${magenta}Y$none]):") " record
			if [[ -z "$record" ]]; then
				error
			else
				if [[ "$record" == [Yy] ]]; then
					domain_check
					echo
					echo
					echo -e "$yellow Domain name Resolution = ${cyan}I'm sure it has been resolved.$none"
					echo "----------------------------------------------------------------"
					echo
					pause
					# domain_check
					backup_config domain
					domain=$new_domain
					caddy_config
					config
					clear
					view_v2ray_config_info
					# download_v2ray_config_ask
					break
				else
					error
				fi
			fi

		done
	else
		echo
		echo -e "$red Sorry...can't modify...$none"
		echo
		echo -e " Note..TLS domain name is only for ${yellow}WebSocket + TLS$none or ${yellow}HTTP/2$none and $yellow automatically config TLS = turn on$none"
		echo
		echo -e " current tranportation protocol: ${cyan}${transport[$v2ray_transport - 1]}${none}"
		echo
		if [[ $caddy ]]; then
			echo -e " automatically config TLS = ${cyan}turn on$none"
		else
			echo -e " automatically config TLS = $red turn off$none"
		fi
		echo
	fi
}
change_path_config() {
	if [[ $v2ray_transport == [45] ]] && [[ $caddy && $is_path ]]; then
		echo
		while :; do
			echo -e "Please input the ${magenta} diffluence path $none , for example /beowulf , only beowulf need to input"
			read -p "$(echo -e "(current: [${cyan}/${path}$none]):")" new_path
			[[ -z $new_path ]] && error && continue

			case $new_path in
			$path)
				echo
				echo -e " dude...same as current path...no need to modify "
				echo
				error
				;;
			*[/$]*)
				echo
				echo -e " This script is a shit. So the diffluence path can't include $red / ${none}or$red $ $none.... "
				echo
				error
				;;
			*)
				echo
				echo
				echo -e "$yellow diffluence path = ${cyan}/${new_path}$none"
				echo "----------------------------------------------------------------"
				echo
				break
				;;
			esac
		done
		pause
		backup_config path
		path=$new_path
		caddy_config
		config
		clear
		view_v2ray_config_info
		# download_v2ray_config_ask
	elif [[ $v2ray_transport == [45] ]] && [[ $caddy ]]; then
		path_config_ask
		if [[ $new_path ]]; then
			backup_config +path
			path=$new_path
			proxy_site=$new_proxy_site
			is_path=true
			caddy_config
			config
			clear
			view_v2ray_config_info
			# download_v2ray_config_ask
		else
			echo
			echo
			echo " thumb up.... give up to config website disguise and diffluence"
			echo
			echo
		fi
	else
		echo
		echo -e "$red Sorry...can't modify...$none"
		echo
		echo -e " Note..only need when tranportation protocol is  ${yellow}WebSocket + TLS$none or ${yellow}HTTP/2$none and $yellow automatically config TLS = turn on$none"
		echo
		echo -e " current tranportation protocol: ${cyan}${transport[$v2ray_transport - 1]}${none}"
		echo
		if [[ $caddy ]]; then
			echo -e " automatically config TLS = ${cyan}turn on$none"
		else
			echo -e " automatically config TLS = $red turn off$none"
		fi
		echo
		change_v2ray_transport_ask
	fi

}
change_proxy_site_config() {
	if [[ $v2ray_transport == [45] ]] && [[ $caddy && $is_path ]]; then
		echo
		while :; do
			echo -e "Please input ${magenta} a normal $none ${cyan}URL$none to act as  ${cyan}website disguise$none , for example https://outlook.live.com/owa/"
		echo -e "For example...Your current domain name is  $green $domain$none , the disguising URL will be https://outlook.live.com/owa/"
		echo -e "And when you open your domain name ...the content from https://outlook.live.com/owa/ will be shown."
		echo -e "Actually a reverse proxy...it's OK..."
		echo -e "If fail to disguise...you can modify v2ray config to disguise"
			read -p "$(echo -e "(current disguising path: [${cyan}${proxy_site}$none]):")" new_proxy_site
			[[ -z $new_proxy_site ]] && error && continue

			case $new_proxy_site in
			*[#$]*)
				echo
				echo -e " This scrip is a shit..So the disguiseing URL can't include $red # ${none}or$red $ $none.... "
				echo
				error
				;;
			*)
				echo
				echo
				echo -e "$yellow disguising URL = ${cyan}${new_proxy_site}$none"
				echo "----------------------------------------------------------------"
				echo
				break
				;;
			esac
		done
		pause
		backup_config proxy_site
		proxy_site=$new_proxy_site
		caddy_config
		echo
		echo
		echo " Alas...It seems to modify successfully..."
		echo
		echo -e " open your domain name ${cyan}https://${domain}$none to check it."
		echo
		echo
	elif [[ $v2ray_transport == [45] ]] && [[ $caddy ]]; then
		path_config_ask
		if [[ $new_path ]]; then
			backup_config +path
			path=$new_path
			proxy_site=$new_proxy_site
			is_path=true
			caddy_config
			config
			clear
			view_v2ray_config_info
			# download_v2ray_config_ask
		else
			echo
			echo
			echo " thumb up....give up to config website disguise and diffluence"
			echo
			echo
		fi
	else
		echo
		echo -e "$red Sorry...can't modify ...$none"
		echo
		echo -e " Note..only need when tranportation protocol is  ${yellow}WebSocket + TLS$none or ${yellow}HTTP/2$none and $yellow automatically config TLS = turn on$none"
		echo
		echo -e " current tranportation protocol: ${cyan}${transport[$v2ray_transport - 1]}${none}"
		echo
		if [[ $caddy ]]; then
			echo -e " automatically config TLS = ${cyan}turn on$none"
		else
			echo -e " automatically config TLS = $red turn off$none"
		fi
		echo
		change_v2ray_transport_ask
	fi

}
domain_check() {
	# test_domain=$(dig $new_domain +short)
	test_domain=$(ping $new_domain -c 1 | grep -oE -m1 "([0-9]{1,3}\.){3}[0-9]{1,3}")
	if [[ $test_domain != $ip ]]; then
		echo
		echo -e "$red domain name resolution error....$none"
		echo
		echo -e " your domain name: $yellow $domain$none can't be resolved to : $cyan $ip $none"
		echo
		echo -e " you current domain name's resolved to: $cyan $test_domain $none"
		echo
		echo "Note...If your domain name server uses Cloudflare ..click the icon of ..make it gray."
		echo
		exit 1
	fi
}
disable_path() {
	if [[ $v2ray_transport == [45] ]] && [[ $caddy && $is_path ]]; then
		echo

		while :; do
			echo -e "Need to turn off ${yellow}website disguising and diffluence${none} [${magenta}Y/N$none]"
			read -p "$(echo -e "(default [${cyan}N$none]):") " y_n
			[[ -z "$y_n" ]] && y_n="n"
			if [[ "$y_n" == [Yy] ]]; then
				echo
				echo
				echo -e "$yellow turn off website disguising and diffluence = $cyan Yes$none"
				echo "----------------------------------------------------------------"
				echo
				pause
				backup_config -path
				is_path=''
				caddy_config
				config
				clear
				view_v2ray_config_info
				# download_v2ray_config_ask
				break
			elif [[ "$y_n" == [Nn] ]]; then
				echo
				echo -e " $green cancel to turn off website disguising and diffluence ....$none"
				echo
				break
			else
				error
			fi

		done
	else
		echo
		echo -e "$red Sorry...cant' modify...$none"
		echo
		echo -e " current tranportation protocol${cyan}${transport[$v2ray_transport - 1]}${none}"
		echo
		if [[ $caddy ]]; then
			echo -e " automatically config TLS = ${cyan}turn on$none"
		else
			echo -e " automatically config TLS = $red turn off$none"
		fi
		echo
		if [[ $is_path ]]; then
			echo -e " diffluence = ${cyan}turn on$none"
		else
			echo -e " diffluence = $red turn off$none"
		fi
		echo
		echo -e " only when tranportation protocol is WebSocket + TLS or HTTP/2, automatically config TLS = ${cyan}turn on$none, diffluence = ${cyan}turn on$none, it can be modified."
		echo

	fi
}
blocked_hosts() {
	if [[ $ban_ad ]]; then
		local _info="$green turn on$none"
	else
		local _info="$red turn off$none"
	fi
	_opt=''
	while :; do
		echo
		echo -e "$yellow 1. $none turn on Ad blocking"
		echo
		echo -e "$yellow 2. $none turn off Ad blocking"
		echo
		echo -e "current ad blocking: $_info"
		echo
		read -p "$(echo -e "Please choose [${magenta}1-2$none]:")" _opt
		if [[ -z $_opt ]]; then
			error
		else
			case $_opt in
			1)
				if [[ $ban_ad ]]; then
					echo
					echo -e " Dude...current ad blocking: $_info.....no need to modify"
					echo
				else
					echo
					echo
					echo -e "$yellow ad blocking = $cyan turn on$none"
					echo "----------------------------------------------------------------"
					echo
					pause
					backup_config +ad
					ban_ad=true
					config
					echo
					echo
					echo -e "$green ad blocking has been turned on...$none"
					echo
				fi
				break
				;;
			2)
				if [[ $ban_ad ]]; then
					echo
					echo
					echo -e "$yellow Ad blocking = $cyan turn off$none"
					echo "----------------------------------------------------------------"
					echo
					pause
					backup_config -ad
					ban_ad=''
					config
					echo
					echo
					echo -e "$red ad blocking has been turned off...$none"
					echo
				else
					echo
					echo -e " Dude...current ad blocking: $_info.....no need to modify"
					echo
				fi
				break
				;;
			*)
				error
				;;
			esac
		fi
	done

}
change_v2ray_alterId() {
	echo
	while :; do
		echo -e "Please input ${yellow}alterId${none} [${magenta}0-65535$none]"
		read -p "$(echo -e "(current alterId: ${cyan}$alterId$none):") " new_alterId
		[[ -z $new_alterId ]] && error && continue
		case $new_alterId in
		$alterId)
			echo
			echo -e " Dude...same as current alterId...no need to modify"
			echo
			error
			;;
		[0-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
			echo
			echo
			echo -e "$yellow alterId = $cyan$new_alterId$none"
			echo "----------------------------------------------------------------"
			echo
			pause
			backup_config alterId
			alterId=$new_alterId
			config
			clear
			view_v2ray_config_info
			# download_v2ray_config_ask
			break
			;;
		*)
			error
			;;
		esac
	done
}

custom_uuid() {
	echo
	while :; do
		echo -e "Please input $yellow custom UUID$none...(${cyan}UUID the format must be valid!!!$none)"
		read -p "$(echo -e "(current UUID: ${cyan}${v2ray_id}$none)"): " myuuid
		[ -z "$myuuid" ] && error && continue
		case $myuuid in
		$v2ray_id)
			echo
			echo -e " Dude...same as current UUID ... no need to modify "
			echo
			error
			;;
		*[/$]* | *\&*)
			echo
			echo -e " This script is shit..So UUID can't include $red / $none or $red $ $none or $red & $none.... "
			echo
			error
			;;
		*)
			echo
			echo
			echo -e "$yellow UUID = $cyan$myuuid$none"
			echo
			echo -e " If the format of UUID is incorrectly.. V2Ray will fail...use$cyan v2ray reuuid$none to recover"
			echo "----------------------------------------------------------------"
			echo
			pause
			uuid=$myuuid
			backup_config uuid
			v2ray_id=$uuid
			config
			clear
			view_v2ray_config_info
			# download_v2ray_config_ask
			break
			;;
		esac
	done
}
v2ray_service() {
	while :; do
		echo
		echo -e "$yellow 1. $none start V2Ray"
		echo
		echo -e "$yellow 2. $none shutdown V2Ray"
		echo
		echo -e "$yellow 3. $none restart V2Ray"
		echo
		echo -e "$yellow 4. $none view access log"
		echo
		echo -e "$yellow 5. $none view error log"
		echo
		read -p "$(echo -e "Please choose [${magenta}1-5$none]:")" _opt
		if [[ -z $_opt ]]; then
			error
		else
			case $_opt in
			1)
				start_v2ray
				break
				;;
			2)
				stop_v2ray
				break
				;;
			3)
				restart_v2ray
				break
				;;
			4)
				view_v2ray_log
				break
				;;
			5)
				view_v2ray_error_log
				break
				;;
			*)
				error
				;;
			esac
		fi
	done
}
start_v2ray() {
	if [[ $v2ray_pid ]]; then
		echo
		echo -e "${green} V2Ray is running...no need to start$none"
		echo
	else

		# systemctl start v2ray
		service v2ray start >/dev/null 2>&1
		if [[ $? -ne 0 ]]; then
			echo
			echo -e "${red} V2Ray fail to start!$none"
			echo
		else
			echo
			echo -e "${green} V2Ray has been started!$none"
			echo
		fi

	fi
}
stop_v2ray() {
	if [[ $v2ray_pid ]]; then
		# systemctl stop v2ray
		service v2ray stop >/dev/null 2>&1
		echo
		echo -e "${green} V2Ray has been shut down!$none"
		echo
	else
		echo
		echo -e "${red} V2Ray not running$none"
		echo
	fi
}
restart_v2ray() {
	# systemctl restart v2ray
	service v2ray restart >/dev/null 2>&1
	if [[ $? -ne 0 ]]; then
		echo
		echo -e "${red} V2Ray fail to restart!$none"
		echo
	else
		echo
		echo -e "${green} V2Ray restart complete $none"
		echo
	fi
}
view_v2ray_log() {
	echo
	echo -e "$green Press Ctrl + C to quit...$none"
	echo
	tail -f /var/log/v2ray/access.log
}
view_v2ray_error_log() {
	echo
	echo -e "$green Press Ctrl + C to quit...$none"
	echo
	tail -f /var/log/v2ray/error.log
}
download_v2ray_config() {
	while :; do
		echo
		echo -e "$yellow 1. $none download V2Ray client config file (only Xshell supported)"
		echo
		echo -e "$yellow 2. $none generate V2Ray client config file download url"
		echo
		echo -e "$yellow 3. $none generate V2Ray config info URL"
		echo
		echo -e "$yellow 4. $none generate V2Ray config QR code URL"
		echo
		read -p "$(echo -e "Please choose [${magenta}1-4$none]:")" other_opt
		if [[ -z $other_opt ]]; then
			error
		else
			case $other_opt in
			1)
				get_v2ray_config
				break
				;;
			2)
				get_v2ray_config_link
				break
				;;
			3)
				get_v2ray_config_info_link
				break
				;;
			4)
				get_v2ray_config_qr_link
				break
				;;
			*)
				error
				;;
			esac
		fi
	done
}
get_v2ray_config() {
	config
	echo
	echo " If your current SSH session is not in Xshell...It will block to downlod V2Ray client config files"
	echo
	while :; do
		read -p "$(echo -e "Don't blur...I'm using Xshell [${magenta}Y$none]:")" is_xshell
		if [[ -z $is_xshell ]]; then
			error
		else
			if [[ $is_xshell == [yY] ]]; then
				echo
				echo "start to download....Please select V2Ray client config files' saving path"
				echo
				local tmpfile="/tmp/vCross_v2ray_config_$RANDOM.json"
				cp -f $v2ray_client_config $tmpfile
				sz $tmpfile
				echo
				echo
				echo -e "$green download completed...$none"
				echo
				# echo -e "$yellow decompress password = ${cyan}vCross$none"
				# echo
				echo -e "$yellow SOCKS listening port = ${cyan}1533${none}"
				echo
				echo -e "${yellow} HTTP listening port = ${cyan}6666$none"
				echo
				echo "V2Ray client user guide: https://233v2.com/post/4/"
				echo
				break
			else
				error
			fi
		fi
	done
	[[ -f $tmpfile ]] && rm -rf $tmpfile

}
get_v2ray_config_link() {
	_load client_file.sh
	_get_client_file
}
create_v2ray_config_text() {

	get_transport_args

	echo
	echo
	echo "---------- V2Ray config info -------------"
	if [[ $v2ray_transport == [45] ]]; then
		if [[ ! $caddy ]]; then
			echo
			echo " Warning!Please manually config TLS...guide: https://233v2.com/post/3/"
		fi
		echo
		echo "(Address) = ${domain}"
		echo
		echo "(Port) = 443"
		echo
		echo "(User ID / UUID) = ${v2ray_id}"
		echo
		echo "(Alter Id) = ${alterId}"
		echo
		echo "(Network) = ${net}"
		echo
		echo "(header type) = ${header}"
		echo
		echo "(host) = ${domain}"
		echo
		echo "(path) = ${_path}"
		echo
		echo "TLS (Enable TLS) = turn on"
		echo
		if [[ $ban_ad ]]; then
			echo " Node: Ad blocking has turned on.."
			echo
		fi
	else
		[[ -z $ip ]] && get_ip
		echo
		echo "(Address) = ${ip}"
		echo
		echo "(Port) = $v2ray_port"
		echo
		echo "(User ID / UUID) = ${v2ray_id}"
		echo
		echo "(Alter Id) = ${alterId}"
		echo
		echo "(Network) = ${net}"
		echo
		echo "(header type) = ${header}"
		echo
	fi
	if [[ $v2ray_transport -ge 18 ]] && [[ $ban_ad ]]; then
		echo "Note: dynamic port turned on...Ad blocking turned on..."
		echo
	elif [[ $v2ray_transport -ge 18 ]]; then
		echo "Note: dynamic port turned on..."
		echo
	elif [[ $ban_ad ]]; then
		echo "Note: Ad blocking turned on.."
		echo
	fi
	echo "---------- END -------------"
	echo
	echo "V2Ray client user guide: https://233v2.com/post/4/"
	echo
}
get_v2ray_config_info_link() {
	echo
	echo -e "$green generating URL.... wait for a while....$none"
	echo
	create_v2ray_config_text >/tmp/vCross_v2ray.txt
	local random=$(echo $RANDOM-$RANDOM-$RANDOM | base64 -w 0)
	local link=$(curl -s --upload-file /tmp/vCross_v2ray.txt "https://transfer.sh/${random}_vCross_v2ray.txt")
	if [[ $link ]]; then
		echo
		echo "---------- V2Ray config URL-------------"
		echo
		echo -e "$yellow URL = $cyan$link$none"
		echo
		echo -e " V2Ray client user guide: https://233v2.com/post/4/"
		echo
		echo "Note...URL will be invalid in 14 days.."
		echo
		echo "Note...Please dont' share the URL....."
		echo
	else
		echo
		echo -e "$red Alas...Error...Please retry$none"
		echo
	fi
	rm -rf /tmp/vCross_v2ray.txt
}
get_v2ray_config_qr_link() {

	create_vmess_URL_config

	_load qr.sh
	_qr_create
}
get_v2ray_vmess_URL_link() {
	create_vmess_URL_config
	local vmess="vmess://$(cat /etc/v2ray/vmess_qr.json | base64 -w 0)"
	echo
	echo "---------- V2Ray vmess URL / V2RayNG v0.4.1+ / V2RayN v2.1+ / only support part of clients -------------"
	echo
	echo -e ${cyan}$vmess${none}
	echo
	rm -rf /etc/v2ray/vmess_qr.json
}
other() {
	while :; do
		echo
		echo -e "$yellow 1. $none install BBR"
		echo
		echo -e "$yellow 2. $none install LotServer"
		echo
		echo -e "$yellow 3. $none uninstall LotServer"
		echo
		read -p "$(echo -e "Please choose [${magenta}1-3$none]:")" _opt
		if [[ -z $_opt ]]; then
			error
		else
			case $_opt in
			1)
				install_bbr
				break
				;;
			2)
				install_lotserver
				break
				;;
			3)
				uninstall_lotserver
				break
				;;
			*)
				error
				;;
			esac
		fi
	done
}
install_bbr() {
	local test1=$(sed -n '/net.ipv4.tcp_congestion_control/p' /etc/sysctl.conf)
	local test2=$(sed -n '/net.core.default_qdisc/p' /etc/sysctl.conf)
	if [[ $test1 == "net.ipv4.tcp_congestion_control = bbr" && $test2 == "net.core.default_qdisc = fq" ]]; then
		echo
		echo -e "$green BBR has turned on...no need to install$none"
		echo
	else
		_load bbr.sh
		_try_enable_bbr
		[[ ! $enable_bbr ]] && bash <(curl -s -L https://github.com/teddysun/across/raw/master/bbr.sh)
	fi
}
install_lotserver() {
	# https://moeclub.org/2017/03/08/14/
	wget --no-check-certificate -qO /tmp/appex.sh "https://raw.githubusercontent.com/0oVicero0/serverSpeeder_Install/master/appex.sh"
	bash /tmp/appex.sh 'install'
	rm -rf /tmp/appex.sh
}
uninstall_lotserver() {
	# https://moeclub.org/2017/03/08/14/
	wget --no-check-certificate -qO /tmp/appex.sh "https://raw.githubusercontent.com/0oVicero0/serverSpeeder_Install/master/appex.sh"
	bash /tmp/appex.sh 'uninstall'
	rm -rf /tmp/appex.sh
}

open_port() {
	if [[ $cmd == "apt-get" ]]; then
		if [[ $1 != "multiport" ]]; then
			# if [[ $cmd == "apt-get" ]]; then
			iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport $1 -j ACCEPT
			iptables -I INPUT -m state --state NEW -m udp -p udp --dport $1 -j ACCEPT
			ip6tables -I INPUT -m state --state NEW -m tcp -p tcp --dport $1 -j ACCEPT
			ip6tables -I INPUT -m state --state NEW -m udp -p udp --dport $1 -j ACCEPT

			# iptables-save >/etc/iptables.rules.v4
			# ip6tables-save >/etc/iptables.rules.v6
			# else
			# 	firewall-cmd --permanent --zone=public --add-port=$1/tcp
			# 	firewall-cmd --permanent --zone=public --add-port=$1/udp
			# 	firewall-cmd --reload
			# fi
		else
			# if [[ $cmd == "apt-get" ]]; then
			local multiport="${v2ray_dynamic_port_start_input}:${v2ray_dynamic_port_end_input}"
			iptables -I INPUT -p tcp --match multiport --dports $multiport -j ACCEPT
			iptables -I INPUT -p udp --match multiport --dports $multiport -j ACCEPT
			ip6tables -I INPUT -p tcp --match multiport --dports $multiport -j ACCEPT
			ip6tables -I INPUT -p udp --match multiport --dports $multiport -j ACCEPT

			# iptables-save >/etc/iptables.rules.v4
			# ip6tables-save >/etc/iptables.rules.v6
			# else
			# 	local multi_port="${v2ray_dynamic_port_start_input}-${v2ray_dynamic_port_end_input}"
			# 	firewall-cmd --permanent --zone=public --add-port=$multi_port/tcp
			# 	firewall-cmd --permanent --zone=public --add-port=$multi_port/udp
			# 	firewall-cmd --reload
			# fi
		fi
		iptables-save >/etc/iptables.rules.v4
		ip6tables-save >/etc/iptables.rules.v6
		# else
		# 	service iptables save >/dev/null 2>&1
		# 	service ip6tables save >/dev/null 2>&1
	fi

}
del_port() {
	if [[ $cmd == "apt-get" ]]; then
		if [[ $1 != "multiport" ]]; then
			# if [[ $cmd == "apt-get" ]]; then
			iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport $1 -j ACCEPT
			iptables -D INPUT -m state --state NEW -m udp -p udp --dport $1 -j ACCEPT
			ip6tables -D INPUT -m state --state NEW -m tcp -p tcp --dport $1 -j ACCEPT
			ip6tables -D INPUT -m state --state NEW -m udp -p udp --dport $1 -j ACCEPT
			# else
			# 	firewall-cmd --permanent --zone=public --remove-port=$1/tcp
			# 	firewall-cmd --permanent --zone=public --remove-port=$1/udp
			# fi
		else
			# if [[ $cmd == "apt-get" ]]; then
			local ports="${v2ray_dynamicPort_start}:${v2ray_dynamicPort_end}"
			iptables -D INPUT -p tcp --match multiport --dports $ports -j ACCEPT
			iptables -D INPUT -p udp --match multiport --dports $ports -j ACCEPT
			ip6tables -D INPUT -p tcp --match multiport --dports $ports -j ACCEPT
			ip6tables -D INPUT -p udp --match multiport --dports $ports -j ACCEPT
			# else
			# 	local ports="${v2ray_dynamicPort_start}-${v2ray_dynamicPort_end}"
			# 	firewall-cmd --permanent --zone=public --remove-port=$ports/tcp
			# 	firewall-cmd --permanent --zone=public --remove-port=$ports/udp
			# fi
		fi
		iptables-save >/etc/iptables.rules.v4
		ip6tables-save >/etc/iptables.rules.v6
		# else
		# 	service iptables save >/dev/null 2>&1
		# 	service ip6tables save >/dev/null 2>&1
	fi
}
update() {
	while :; do
		echo
		echo -e "$yellow 1. $none update V2Ray main program"
		echo
		echo -e "$yellow 2. $none update V2Ray management script"
		echo
		read -p "$(echo -e "Please choose [${magenta}1-2$none]:")" _opt
		if [[ -z $_opt ]]; then
			error
		else
			case $_opt in
			1)
				update_v2ray
				break
				;;
			2)
				update_v2ray.sh
				exit
				break
				;;
			*)
				error
				;;
			esac
		fi
	done
}
update_v2ray() {
	_load download-v2ray.sh
	_update_v2ray_version
}
update_v2ray.sh() {
	if [[ $_test ]]; then
		local latest_version=$(curl -H 'Cache-Control: no-cache' -s -L "https://raw.githubusercontent.com/vCross/v2ray/test/v2ray.sh" | grep '_version' -m1 | cut -d\" -f2)
	else
		local latest_version=$(curl -H 'Cache-Control: no-cache' -s -L "https://raw.githubusercontent.com/vCross/v2ray/master/v2ray.sh" | grep '_version' -m1 | cut -d\" -f2)
	fi

	if [[ ! $latest_version ]]; then
		echo
		echo -e " $red fail to retrieve latest V2Ray!!!$none"
		echo
		echo -e " Please try: $green echo 'nameserver 8.8.8.8' >/etc/resolv.conf $none"
		echo
		echo " and then continue...."
		echo
		exit 1
	fi

	if [[ $latest_version == $_version ]]; then
		echo
		echo -e "$green no new version found $none"
		echo
	else
		echo
		echo -e " $green a new version found....trying to update.......$none"
		echo
		cd /etc/v2ray/vCross/v2ray
		git pull
		cp -f /etc/v2ray/vCross/v2ray/v2ray.sh $_v2ray_sh
		chmod +x $_v2ray_sh
		echo
		echo -e "$green success to update...current V2Ray management script version: ${cyan}$latest_version$none"
		echo
	fi

}
uninstall_v2ray() {
	_load uninstall.sh
}
config() {
	_load config.sh

	if [[ $v2ray_port == "80" ]]; then
		if [[ $cmd == "yum" ]]; then
			[[ $(pgrep "httpd") ]] && systemctl stop httpd >/dev/null 2>&1
			[[ $(command -v httpd) ]] && yum remove httpd -y >/dev/null 2>&1
		else
			[[ $(pgrep "apache2") ]] && service apache2 stop >/dev/null 2>&1
			[[ $(command -v apache2) ]] && apt-get remove apache2* -y >/dev/null 2>&1
		fi
	fi
	do_service restart v2ray
}
backup_config() {
	for keys in $*; do
		case $keys in
		v2ray_transport)
			sed -i "18s/=$v2ray_transport/=$v2ray_transport_opt/" $backup
			;;
		v2ray_port)
			sed -i "21s/=$v2ray_port/=$v2ray_port_opt/" $backup
			;;
		uuid)
			sed -i "24s/=$v2ray_id/=$uuid/" $backup
			;;
		alterId)
			sed -i "27s/=$alterId/=$new_alterId/" $backup
			;;
		v2ray_dynamicPort_start)
			sed -i "30s/=$v2ray_dynamicPort_start/=$v2ray_dynamic_port_start_input/" $backup
			;;
		v2ray_dynamicPort_end)
			sed -i "33s/=$v2ray_dynamicPort_end/=$v2ray_dynamic_port_end_input/" $backup
			;;
		domain)
			sed -i "36s/=$domain/=$new_domain/" $backup
			;;
		caddy)
			sed -i "39s/=/=true/" $backup
			;;
		+ss)
			sed -i "42s/=/=true/; 45s/=$ssport/=$new_ssport/; 48s/=$sspass/=$new_sspass/; 51s/=$ssciphers/=$new_ssciphers/" $backup
			;;
		-ss)
			sed -i "42s/=true/=/" $backup
			;;
		ssport)
			sed -i "45s/=$ssport/=$new_ssport/" $backup
			;;
		sspass)
			sed -i "48s/=$sspass/=$new_sspass/" $backup
			;;
		ssciphers)
			sed -i "51s/=$ssciphers/=$new_ssciphers/" $backup
			;;
		+ad)
			sed -i "54s/=/=true/" $backup
			;;
		-ad)
			sed -i "54s/=true/=/" $backup
			;;
		+path)
			sed -i "57s/=/=true/; 60s/=$path/=$new_path/; 63s#=$proxy_site#=$new_proxy_site#" $backup
			;;
		-path)
			sed -i "57s/=true/=/" $backup
			;;
		path)
			sed -i "60s/=$path/=$new_path/" $backup
			;;
		proxy_site)
			sed -i "63s#=$proxy_site#=$new_proxy_site#" $backup
			;;
		+socks)
			sed -i "66s/=/=true/; 69s/=$socks_port/=$new_socks_port/; 72s/=$socks_username/=$new_socks_username/; 75s/=$socks_userpass/=$new_socks_userpass/;" $backup
			;;
		-socks)
			sed -i "66s/=true/=/" $backup
			;;
		socks_port)
			sed -i "69s/=$socks_port/=$new_socks_port/" $backup
			;;
		socks_username)
			sed -i "72s/=$socks_username/=$new_socks_username/" $backup
			;;
		socks_userpass)
			sed -i "75s/=$socks_userpass/=$new_socks_userpass/" $backup
			;;
		+mtproto)
			sed -i "78s/=/=true/; 81s/=$mtproto_port/=$new_mtproto_port/; 84s/=$mtproto_secret/=$new_mtproto_secret/" $backup
			;;
		-mtproto)
			sed -i "78s/=true/=/" $backup
			;;
		mtproto_port)
			sed -i "81s/=$mtproto_port/=$new_mtproto_port/" $backup
			;;
		mtproto_secret)
			sed -i "84s/=$mtproto_secret/=$new_mtproto_secret/" $backup
			;;
		+bt)
			sed -i "87s/=/=true/" $backup
			;;
		-bt)
			sed -i "87s/=true/=/" $backup
			;;
		esac
	done

}

get_ip() {
	ip=$(curl -s https://ipinfo.io/ip)
	[[ -z $ip ]] && ip=$(curl -s https://api.ip.sb/ip)
	[[ -z $ip ]] && ip=$(curl -s https://api.ipify.org)
	[[ -z $ip ]] && ip=$(curl -s https://ip.seeip.org)
	[[ -z $ip ]] && ip=$(curl -s https://ifconfig.co/ip)
	[[ -z $ip ]] && ip=$(curl -s https://api.myip.com | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}")
	[[ -z $ip ]] && ip=$(curl -s icanhazip.com)
	[[ -z $ip ]] && ip=$(curl -s myip.ipip.net | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}")
	[[ -z $ip ]] && echo -e "\n$red this shit vps can be discarded!$none\n" && exit
}

error() {

	echo -e "\n$red input error!$none\n"

}

pause() {

	read -rsp "$(echo -e "Press$green Enter $none to continue....or press $red Ctrl + C $none to cancel.")" -d $'\n'
	echo
}
do_service() {
	if [[ $systemd ]]; then
		systemctl $1 $2
	else
		service $2 $1
	fi
}
_help() {
	echo
	echo "........... V2Ray management script help .........."
	echo -e "
	${green}v2ray menu $none manage V2Ray (same as v2ray)

	${green}v2ray info $none view V2Ray config

	${green}v2ray config $none modify V2Ray config

	${green}v2ray link $none generate V2Ray client config URL

	${green}v2ray textlink $none generate V2Ray config URL

	${green}v2ray qr $none generate V2Ray config QR code URL

	${green}v2ray ss $none modify Shadowsocks config

	${green}v2ray ssinfo $none View Shadowsocks config

	${green}v2ray ssqr $none generate Shadowsocks config QR code URL

	${green}v2ray status $none view V2Ray running state

	${green}v2ray start $none start V2Ray

	${green}v2ray stop $none stop V2Ray

	${green}v2ray restart $none restart V2Ray

	${green}v2ray log $none view V2Ray running log

	${green}v2ray update $none update V2Ray

	${green}v2ray update.sh $none update V2Ray management script

	${green}v2ray uninstall $none uninstall V2Ray
"
}
menu() {
	clear
	while :; do
		echo
		echo "........... V2Ray management $_version.........."
		echo
		echo -e "## V2Ray version: $cyan$v2ray_ver$none  /  V2Ray running state: $v2ray_status ##"
		echo
		echo "help: https://233v2.com/post/1/"
		echo
		echo "feedback: https://github.com/vCross/v2ray/issues"
		echo
		echo "TG: https://t.me/blog233"
		
		echo -e "$yellow  1. $none view V2Ray config"
		echo
		echo -e "$yellow  2. $none modify V2Ray config"
		echo
		echo -e "$yellow  3. $none download V2Ray config / genetrate config URL / genetrate config QR code URL"
		echo
		echo -e "$yellow  4. $none View Shadowsocks config / genetrate config QR code URL"
		echo
		echo -e "$yellow  5. $none modify Shadowsocks config"
		echo
		echo -e "$yellow  6. $none View MTProto config / modify MTProto config"
		echo
		echo -e "$yellow  7. $none View Socks5 config / modify Socks5 config"
		echo
		echo -e "$yellow  8. $none start / stop / restart / view log"
		echo
		echo -e "$yellow  9. $none update V2Ray / update V2Ray management script"
		echo
		echo -e "$yellow 10. $none uninstall V2Ray"
		echo
		echo -e "$yellow 11. $none others"
		echo
		echo -e "Tips...If you don't wana do anything...按$yellow Ctrl + C $none to quit"
		echo
		read -p "$(echo -e "Please select from manu: [${magenta}1-11$none]:")" choose
		if [[ -z $choose ]]; then
			exit 1
		else
			case $choose in
			1)
				view_v2ray_config_info
				break
				;;
			2)
				change_v2ray_config
				break
				;;
			3)
				download_v2ray_config
				break
				;;
			4)
				get_shadowsocks_config
				break
				;;
			5)
				change_shadowsocks_config
				break
				;;
			6)
				_load mtproto.sh
				_mtproto_main
				break
				;;
			7)
				_load socks.sh
				_socks_main
				break
				;;
			8)
				v2ray_service
				break
				;;
			9)
				update
				break
				;;
			10)
				uninstall_v2ray
				break
				;;
			11)
				other
				break
				;;
			*)
				error
				;;
			esac
		fi
	done
}
args=$1
[ -z $1 ] && args="menu"
case $args in
menu)
	menu
	;;
i | info)
	view_v2ray_config_info
	;;
c | config)
	change_v2ray_config
	;;
l | link)
	get_v2ray_config_link
	;;
L | infolink)
	get_v2ray_config_info_link
	;;
q | qr)
	get_v2ray_config_qr_link
	;;
s | ss)
	change_shadowsocks_config
	;;
S | ssinfo)
	view_shadowsocks_config_info
	;;
Q | ssqr)
	get_shadowsocks_config_qr_link
	;;
socks)
	_load socks.sh
	_socks_main
	;;
socksinfo)
	_load socks.sh
	_view_socks_info
	;;
tg)
	_load mtproto.sh
	_mtproto_main
	;;
tginfo)
	_load mtproto.sh
	_view_mtproto_info
	;;
bt)
	_load bt.sh
	_ban_bt_main
	;;
status)
	echo
	if [[ $v2ray_transport == [45] && $caddy ]]; then
		echo -e " V2Ray state: $v2ray_status  /  Caddy state: $caddy_run_status"
	else
		echo -e " V2Ray state: $v2ray_status"
	fi
	echo
	;;
start)
	start_v2ray
	;;
stop)
	stop_v2ray
	;;
restart)
	[[ $v2ray_transport == [45] && $caddy ]] && do_service restart caddy
	restart_v2ray
	;;
reload)
	config
	[[ $v2ray_transport == [45] && $caddy ]] && caddy_config
	clear
	view_v2ray_config_info
	;;
time)
	date -s "$(curl -sI g.cn | grep Date | cut -d' ' -f3-6)Z"
	;;
log)
	view_v2ray_log
	;;
url | URL)
	get_v2ray_vmess_URL_link
	;;
u | update)
	update_v2ray
	;;
U | update.sh)
	update_v2ray.sh
	exit
	;;
un | uninstall)
	uninstall_v2ray
	;;
reinstall)
	uninstall_v2ray
	if [[ $is_uninstall_v2ray ]]; then
		cd
		cd - >/dev/null 2>&1
		bash <(curl -s -L https://git.io/v2ray.sh)
	fi
	;;
[aA][Ii] | [Dd])
	change_v2ray_alterId
	;;
[aA][Ii][aA][Ii] | [Dd][Dd])
	custom_uuid
	;;
reuuid)
	backup_config uuid
	v2ray_id=$uuid
	config
	clear
	view_v2ray_config_info
	# download_v2ray_config_ask
	;;
v | version)
	echo
	echo -e " current V2Ray version: ${green}$v2ray_ver$none  /  current V2Ray management script version: ${cyan}$_version$none"
	echo
	;;
bbr)
	other
	;;
help | *)
	_help
	;;
esac
