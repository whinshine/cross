#!/bin/bash

red='\e[91m'
green='\e[92m'
yellow='\e[93m'
magenta='\e[95m'
cyan='\e[96m'
none='\e[0m'
_red() { echo -e ${red}$*${none}; }
_green() { echo -e ${green}$*${none}; }
_yellow() { echo -e ${yellow}$*${none}; }
_magenta() { echo -e ${magenta}$*${none}; }
_cyan() { echo -e ${cyan}$*${none}; }

# Root
[[ $(id -u) != 0 ]] && echo -e "\n Hello......Please run with user ${red}root ${yellow}~(^_^) ${none}\n" && exit 1

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
	Ohoh......This ${red}shit script${none} doesn't support your system.${yellow}(-_-) ${none}

	Note: only Ubuntu 16+ / Debian 8+ / CentOS 7+ supported
	" && exit 1
	;;
esac

# stupid detection method
if [[ $(command -v apt-get) || $(command -v yum) ]] && [[ $(command -v systemctl) ]]; then

	if [[ $(command -v yum) ]]; then

		cmd="yum"

	fi

else

	echo -e " 
	Ohoh......this ${red}shit script${none} doesn't support your system. ${yellow}(-_-) ${none}

	Note: only Ubuntu 16+ / Debian 8+ / CentOS 7+ supported
	" && exit 1

fi

uuid=$(cat /proc/sys/kernel/random/uuid)
old_id="e55c8d17-2cf3-b21a-bcf1-eeacb011ed79"
v2ray_server_config="/etc/v2ray/config.json"
v2ray_client_config="/etc/v2ray/vCross_v2ray_config.json"
backup="/etc/v2ray/vCross_v2ray_backup.conf"
_v2ray_sh="/usr/local/sbin/v2ray"
systemd=true
# _test=true

transport=(
	TCP
	TCP_HTTP
	WebSocket
	"WebSocket + TLS"
	HTTP/2
	mKCP
	mKCP_utp
	mKCP_srtp
	mKCP_wechat-video
	mKCP_dtls
	mKCP_wireguard
	QUIC
	QUIC_utp
	QUIC_srtp
	QUIC_wechat-video
	QUIC_dtls
	QUIC_wireguard
	TCP_dynamicPort
	TCP_HTTP_dynamicPort
	WebSocket_dynamicPort
	mKCP_dynamicPort
	mKCP_utp_dynamicPort
	mKCP_srtp_dynamicPort
	mKCP_wechat-video_dynamicPort
	mKCP_dtls_dynamicPort
	mKCP_wireguard_dynamicPort
	QUIC_dynamicPort
	QUIC_utp_dynamicPort
	QUIC_srtp_dynamicPort
	QUIC_wechat-video_dynamicPort
	QUIC_dtls_dynamicPort
	QUIC_wireguard_dynamicPort
)

ciphers=(
	aes-128-cfb
	aes-256-cfb
	chacha20
	chacha20-ietf
	aes-128-gcm
	aes-256-gcm
	chacha20-ietf-poly1305
)

_load() {
	local _dir="/etc/v2ray/vCross/v2ray/src/"
	. "${_dir}$@"
}
_sys_timezone() {
	IS_OPENVZ=
	if hostnamectl status | grep -q openvz; then
		IS_OPENVZ=1
	fi

	echo
	timedatectl set-timezone Asia/Shanghai
	timedatectl set-ntp true
	echo "has modidied your timezone to Asia/Shanghai and synchronized system time via systemd-timesyncd."
	echo

	if [[ $IS_OPENVZ ]]; then
		echo
		echo -e "Your vps is  ${yellow}Openvz${none} , so it's suggested to use ${yellow}v2ray mkcp.${none}"
		echo -e "Note: ${yellow}Openvz${none} , system time can't be synchronized in vps."
		echo -e "If system time differentiate actual time ${yellow}up to 90s${none}, v2ray will not communicate correctly. Please send email to your VPS provider to correct system time."
	fi
}

_sys_time() {
	echo -e "\nsystem time:${yellow}"
	timedatectl status | sed -n '1p;4p'
	echo -e "${none}"
	[[ $IS_OPENV ]] && pause
}
v2ray_config() {
	# clear
	echo
	while :; do
		echo -e "Please select "$yellow"V2Ray"$none" protocol [${magenta}1-${#transport[*]}$none]"
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
		echo "Note1: the items including [dynamicPort] will use dynamic ports.."
		echo "Note2: [utp | srtp | wechat-video | dtls | wireguard] will be disguised as [BT | video talking | wechat video | DTLS 1.2 data diagram | WireGuard datagram] respectively."
		echo
		read -p "$(echo -e "(default protocol: ${cyan}TCP$none)"):" v2ray_transport
		[ -z "$v2ray_transport" ] && v2ray_transport=1
		case $v2ray_transport in
		[1-9] | [1-2][0-9] | 3[0-2])
			echo
			echo
			echo -e "$yellow V2Ray protocol = $cyan${transport[$v2ray_transport - 1]}$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		*)
			error
			;;
		esac
	done
	v2ray_port_config
}
v2ray_port_config() {
	case $v2ray_transport in
	4 | 5)
		tls_config
		;;
	*)
		local random=$(shuf -i20001-65535 -n1)
		while :; do
			echo -e "Please input "$yellow"V2Ray"$none" port ["$magenta"1-65535"$none"]"
			read -p "$(echo -e "(default port: ${cyan}${random}$none):")" v2ray_port
			[ -z "$v2ray_port" ] && v2ray_port=$random
			case $v2ray_port in
			[1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
				echo
				echo
				echo -e "$yellow V2Ray port = $cyan$v2ray_port$none"
				echo "----------------------------------------------------------------"
				echo
				break
				;;
			*)
				error
				;;
			esac
		done
		if [[ $v2ray_transport -ge 18 ]]; then
			v2ray_dynamic_port_start
		fi
		;;
	esac
}

v2ray_dynamic_port_start() {

	while :; do
		echo -e "Please input "$yellow"V2Ray dynamic starting port from  "$none"scope ["$magenta"1-65535"$none"]"
		read -p "$(echo -e "(default starting port: ${cyan}10000$none):")" v2ray_dynamic_port_start_input
		[ -z $v2ray_dynamic_port_start_input ] && v2ray_dynamic_port_start_input=10000
		case $v2ray_dynamic_port_start_input in
		$v2ray_port)
			echo
			echo " Can't be same with V2Ray port..."
			echo
			echo -e " Current V2Ray port: ${cyan}$v2ray_port${none}"
			error
			;;
		[1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
			echo
			echo
			echo -e "$yellow V2Ray dynamic starting port = $cyan$v2ray_dynamic_port_start_input$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		*)
			error
			;;
		esac

	done

	if [[ $v2ray_dynamic_port_start_input -lt $v2ray_port ]]; then
		lt_v2ray_port=true
	fi

	v2ray_dynamic_port_end
}
v2ray_dynamic_port_end() {

	while :; do
		echo -e "Please input "$yellow"V2Ray dynamic ending port from "$none" scope ["$magenta"1-65535"$none"]"
		read -p "$(echo -e "(default ending port: ${cyan}20000$none):")" v2ray_dynamic_port_end_input
		[ -z $v2ray_dynamic_port_end_input ] && v2ray_dynamic_port_end_input=20000
		case $v2ray_dynamic_port_end_input in
		[1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])

			if [[ $v2ray_dynamic_port_end_input -le $v2ray_dynamic_port_start_input ]]; then
				echo
				echo " Can't be less or equal to V2Ray dynamic starting port."
				echo
				echo -e " Current V2Ray dynamic starting port: ${cyan}$v2ray_dynamic_port_start_input${none}"
				error
			elif [ $lt_v2ray_port ] && [[ ${v2ray_dynamic_port_end_input} -ge $v2ray_port ]]; then
				echo
				echo " V2Ray dynamic ending port scope can't include V2Ray port..."
				echo
				echo -e " Current V2Ray port: ${cyan}$v2ray_port${none}"
				error
			else
				echo
				echo
				echo -e "$yellow V2Ray dynamic ending port = $cyan$v2ray_dynamic_port_end_input$none"
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

tls_config() {

	echo
	local random=$(shuf -i20001-65535 -n1)
	while :; do
		echo -e "Please input "$yellow"V2Ray"$none" port ["$magenta"1-65535"$none"], port "$magenta"80"$none" or"$magenta"443"$none" can't be selected."
		read -p "$(echo -e "(default port: ${cyan}${random}$none):")" v2ray_port
		[ -z "$v2ray_port" ] && v2ray_port=$random
		case $v2ray_port in
		80)
			echo
			echo " ...It's already said port 80 can't be selected..."
			error
			;;
		443)
			echo
			echo " ..It's already said port 443 can't be selected..."
			error
			;;
		[1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
			echo
			echo
			echo -e "$yellow V2Ray port = $cyan$v2ray_port$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		*)
			error
			;;
		esac
	done

	while :; do
		echo
		echo -e "Please input a $magenta corrected domain name$none,it MUST be NORMAL!"
		read -p "(For example:heidark.ga): " domain
		[ -z "$domain" ] && error && continue
		echo
		echo
		echo -e "$yellow your domain name = $cyan$domain$none"
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

		read -p "$(echo -e "(The domain name has corrected associated? [${magenta} Y $none]):") " record
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

	if [[ $v2ray_transport -ne 5 ]]; then
		auto_tls_config
	else
		caddy=true
		install_caddy_info="open"
	fi

	if [[ $caddy ]]; then
		path_config_ask
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
				caddy=true
				install_caddy_info="open"
				echo
				echo
				echo -e "$yellow config TLS automatically = $cyan$install_caddy_info$none"
				echo "----------------------------------------------------------------"
				echo
				break
			elif [[ "$auto_install_caddy" == [Nn] ]]; then
				install_caddy_info="close"
				echo
				echo
				echo -e "$yellow config TLS automatically = $cyan$install_caddy_info$none"
				echo "----------------------------------------------------------------"
				echo
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
		echo -e "Turn on website disguise and diffluence?: [${magenta}Y/N$none]"
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
			echo -e "$yellow website disguise and diffluence = $cyan turn off $none"
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
		read -p "$(echo -e "(default: [${cyan}beowulf$none]):")" path
		[[ -z $path ]] && path="beowulf"

		case $path in
		*[/$]*)
			echo
			echo -e " This script is a shit. So the diffluence path can't include $red / ${none}or$red $ $none.... "
			echo
			error
			;;
		*)
			echo
			echo
			echo -e "$yellow diffluence path = ${cyan}/${path}$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		esac
	done
	is_path=true
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
		read -p "$(echo -e "(default: [${cyan}https://outlook.live.com/owa/$none]):")" proxy_site
		[[ -z $proxy_site ]] && proxy_site="https://outlook.live.com/owa/"

		case $proxy_site in
		*[#$]*)
			echo
			echo -e " This scrip is a shit..So the disguiseing URL can't include $red # ${none}or$red $ $none.... "
			echo
			error
			;;
		*)
			echo
			echo
			echo -e "$yellow disguising URL = ${cyan}${proxy_site}$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		esac
	done
}

blocked_hosts() {
	echo
	while :; do
		echo -e "Turn on AD blocking(will lower performance)? [${magenta}Y/N$none]"
		read -p "$(echo -e "(default [${cyan}N$none]):")" blocked_ad
		[[ -z $blocked_ad ]] && blocked_ad="n"

		case $blocked_ad in
		Y | y)
			blocked_ad_info="turn on"
			ban_ad=true
			echo
			echo
			echo -e "$yellow AD blocking = $cyan turn on$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		N | n)
			blocked_ad_info="turn off"
			echo
			echo
			echo -e "$yellow AD blocking = $cyan turn off$none"
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
shadowsocks_config() {

	echo

	while :; do
		echo -e "Turn on ${yellow}Shadowsocks${none}? [${magenta}Y/N$none]"
		read -p "$(echo -e "(default [${cyan}N$none]):") " install_shadowsocks
		[[ -z "$install_shadowsocks" ]] && install_shadowsocks="n"
		if [[ "$install_shadowsocks" == [Yy] ]]; then
			echo
			shadowsocks=true
			shadowsocks_port_config
			break
		elif [[ "$install_shadowsocks" == [Nn] ]]; then
			break
		else
			error
		fi

	done

}

shadowsocks_port_config() {
	local random=$(shuf -i20001-65535 -n1)
	while :; do
		echo -e "Please input "$yellow"Shadowsocks"$none" port ["$magenta"1-65535"$none"], can't be same with "$yellow"V2Ray"$none" port"
		read -p "$(echo -e "(default port: ${cyan}${random}$none):") " ssport
		[ -z "$ssport" ] && ssport=$random
		case $ssport in
		$v2ray_port)
			echo
			echo " cant't be same with V2Ray port...."
			error
			;;
		[1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
			if [[ $v2ray_transport == [45] ]]; then
				local tls=ture
			fi
			if [[ $tls && $ssport == "80" ]] || [[ $tls && $ssport == "443" ]]; then
				echo
				echo -e "As you's chosen  "$green"WebSocket + TLS $none or $green HTTP/2"$none" protocol."
				echo
				echo -e "You can't choose port "$magenta"80"$none" or "$magenta"443"$none" "
				error
			elif [[ $v2ray_dynamic_port_start_input == $ssport || $v2ray_dynamic_port_end_input == $ssport ]]; then
				local multi_port="${v2ray_dynamic_port_start_input} - ${v2ray_dynamic_port_end_input}"
				echo
				echo " Sorry, this port conflict with V2ray dynamic ports, current V2Ray dynamic port scope: $multi_port"
				error
			elif [[ $v2ray_dynamic_port_start_input -lt $ssport && $ssport -le $v2ray_dynamic_port_end_input ]]; then
				local multi_port="${v2ray_dynamic_port_start_input} - ${v2ray_dynamic_port_end_input}"
				echo
				echo " Sorry, this port conflict with V2Ray dynamic ports, current V2Ray dynamic port scope: $multi_port"
				error
			else
				echo
				echo
				echo -e "$yellow Shadowsocks port = $cyan$ssport$none"
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

	shadowsocks_password_config
}
shadowsocks_password_config() {

	while :; do
		echo -e "Please input "$yellow"Shadowsocks"$none" password"
		read -p "$(echo -e "(default password: ${cyan}vCross_Danes$none)"): " sspass
		[ -z "$sspass" ] && sspass="vCross_Danes"
		case $sspass in
		*[/$]*)
			echo
			echo -e " This script is a shit..So password can't include $red / ${none}or$red $ $none.... "
			echo
			error
			;;
		*)
			echo
			echo
			echo -e "$yellow Shadowsocks password = $cyan$sspass$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		esac

	done

	shadowsocks_ciphers_config
}
shadowsocks_ciphers_config() {

	while :; do
		echo -e "Please input "$yellow"Shadowsocks"$none" encryption protocol [${magenta}1-${#ciphers[*]}$none]"
		for ((i = 1; i <= ${#ciphers[*]}; i++)); do
			ciphers_show="${ciphers[$i - 1]}"
			echo
			echo -e "$yellow $i. $none${ciphers_show}"
		done
		echo
		read -p "$(echo -e "(default encryption protocol: ${cyan}${ciphers[6]}$none)"):" ssciphers_opt
		[ -z "$ssciphers_opt" ] && ssciphers_opt=7
		case $ssciphers_opt in
		[1-7])
			ssciphers=${ciphers[$ssciphers_opt - 1]}
			echo
			echo
			echo -e "$yellow Shadowsocks encryption protocol = $cyan${ssciphers}$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		*)
			error
			;;
		esac

	done
	pause
}

install_info() {
	clear
	echo
	echo " ....ready to install..check all the configs OK..."
	echo
	echo "---------- Installation information -------------"
	echo
	echo -e "$yellow V2Ray protocol = $cyan${transport[$v2ray_transport - 1]}$none"

	if [[ $v2ray_transport == [45] ]]; then
		echo
		echo -e "$yellow V2Ray port = $cyan$v2ray_port$none"
		echo
		echo -e "$yellow your domain name = $cyan$domain$none"
		echo
		echo -e "$yellow domain name resolution = ${cyan}I'm sure the domain name has been resolved correctedly.$none"
		echo
		echo -e "$yellow config TLS automatically = $cyan$install_caddy_info$none"

		if [[ $ban_ad ]]; then
			echo
			echo -e "$yellow AD blocking = $cyan$blocked_ad_info$none"
		fi
		if [[ $is_path ]]; then
			echo
			echo -e "$yellow diffluence = ${cyan}/${path}$none"
		fi
	elif [[ $v2ray_transport -ge 18 ]]; then
		echo
		echo -e "$yellow V2Ray port = $cyan$v2ray_port$none"
		echo
		echo -e "$yellow V2Ray dynamic port scope = $cyan${v2ray_dynamic_port_start_input} - ${v2ray_dynamic_port_end_input}$none"

		if [[ $ban_ad ]]; then
			echo
			echo -e "$yellow AD blocking = $cyan$blocked_ad_info$none"
		fi
	else
		echo
		echo -e "$yellow V2Ray port = $cyan$v2ray_port$none"

		if [[ $ban_ad ]]; then
			echo
			echo -e "$yellow AD blocking = $cyan$blocked_ad_info$none"
		fi
	fi
	if [ $shadowsocks ]; then
		echo
		echo -e "$yellow Shadowsocks port = $cyan$ssport$none"
		echo
		echo -e "$yellow Shadowsocks password = $cyan$sspass$none"
		echo
		echo -e "$yellow Shadowsocks encryption protocol = $cyan${ssciphers}$none"
	else
		echo
		echo -e "$yellow config Shadowsocks = ${cyan}not config${none}"
	fi
	echo
	echo "---------- END -------------"
	echo
	pause
	echo
}

domain_check() {
	# if [[ $cmd == "yum" ]]; then
	# 	yum install bind-utils -y
	# else
	# 	$cmd install dnsutils -y
	# fi
	# test_domain=$(dig $domain +short)
	test_domain=$(ping $domain -c 1 | grep -oE -m1 "([0-9]{1,3}\.){3}[0-9]{1,3}")
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

install_caddy() {
	# download caddy file then install
	_load download-caddy.sh
	_download_caddy_file
	_install_caddy_service
	caddy_config

}
caddy_config() {
	# local email=$(shuf -i1-10000000000 -n1)
	_load caddy-config.sh

	# systemctl restart caddy
	do_service restart caddy
}

install_v2ray() {
	$cmd update -y
	if [[ $cmd == "apt-get" ]]; then
		$cmd install -y lrzsz git zip unzip curl wget qrencode libcap2-bin dbus
	else
		# $cmd install -y lrzsz git zip unzip curl wget qrencode libcap iptables-services
		$cmd install -y lrzsz git zip unzip curl wget qrencode libcap
	fi
	ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	[ -d /etc/v2ray ] && rm -rf /etc/v2ray
	# date -s "$(curl -sI g.cn | grep Date | cut -d' ' -f3-6)Z"
	_sys_timezone
	_sys_time

	if [[ $local_install ]]; then
		if [[ ! -d $(pwd)/config ]]; then
			echo
			echo -e "$red Ohoh...fail to install...$none"
			echo
			echo -e " Please make sure you has upload the completed V2Ray installation script of to current directory ${green}$(pwd) $none"
			echo
			exit 1
		fi
		mkdir -p /etc/v2ray/vCross/v2ray
		cp -rf $(pwd)/* /etc/v2ray/vCross/v2ray
	else
		pushd /tmp
		git clone https://github.com/whinshine/cross.git -b "$_gitbranch" /etc/v2ray/vCross/v2ray --depth=1
		popd
	fi

	if [[ ! -d /etc/v2ray/vCross/v2ray ]]; then
		echo
		echo -e "$red Ohoh...fail to clone the repository...$none"
		echo
		echo -e " Tips..... Please intall Git: ${green}$cmd install -y git $none and you'll use this script."
		echo
		exit 1
	fi

	# download v2ray file then install
	_load download-v2ray.sh
	_download_v2ray_file
	_install_v2ray_service
	_mkdir_dir
}

open_port() {
	if [[ $cmd == "apt-get" ]]; then
		if [[ $1 != "multiport" ]]; then

			iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport $1 -j ACCEPT
			iptables -I INPUT -m state --state NEW -m udp -p udp --dport $1 -j ACCEPT
			ip6tables -I INPUT -m state --state NEW -m tcp -p tcp --dport $1 -j ACCEPT
			ip6tables -I INPUT -m state --state NEW -m udp -p udp --dport $1 -j ACCEPT

			# firewall-cmd --permanent --zone=public --add-port=$1/tcp
			# firewall-cmd --permanent --zone=public --add-port=$1/udp
			# firewall-cmd --reload

		else

			local multiport="${v2ray_dynamic_port_start_input}:${v2ray_dynamic_port_end_input}"
			iptables -I INPUT -p tcp --match multiport --dports $multiport -j ACCEPT
			iptables -I INPUT -p udp --match multiport --dports $multiport -j ACCEPT
			ip6tables -I INPUT -p tcp --match multiport --dports $multiport -j ACCEPT
			ip6tables -I INPUT -p udp --match multiport --dports $multiport -j ACCEPT

			# local multi_port="${v2ray_dynamic_port_start_input}-${v2ray_dynamic_port_end_input}"
			# firewall-cmd --permanent --zone=public --add-port=$multi_port/tcp
			# firewall-cmd --permanent --zone=public --add-port=$multi_port/udp
			# firewall-cmd --reload

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

config() {
	cp -f /etc/v2ray/vCross/v2ray/config/backup.conf $backup
	cp -f /etc/v2ray/vCross/v2ray/v2ray.sh $_v2ray_sh
	chmod +x $_v2ray_sh

	v2ray_id=$uuid
	alterId=153
	ban_bt=true
	if [[ $v2ray_transport -ge 18 ]]; then
		v2ray_dynamicPort_start=${v2ray_dynamic_port_start_input}
		v2ray_dynamicPort_end=${v2ray_dynamic_port_end_input}
	fi
	_load config.sh

	if [[ $cmd == "apt-get" ]]; then
		cat >/etc/network/if-pre-up.d/iptables <<-EOF
			#!/bin/sh
			/sbin/iptables-restore < /etc/iptables.rules.v4
			/sbin/ip6tables-restore < /etc/iptables.rules.v6
		EOF
		chmod +x /etc/network/if-pre-up.d/iptables
		# else
		# 	[ $(pgrep "firewall") ] && systemctl stop firewalld
		# 	systemctl mask firewalld
		# 	systemctl disable firewalld
		# 	systemctl enable iptables
		# 	systemctl enable ip6tables
		# 	systemctl start iptables
		# 	systemctl start ip6tables
	fi

	[[ $shadowsocks ]] && open_port $ssport
	if [[ $v2ray_transport == [45] ]]; then
		open_port "80"
		open_port "443"
		open_port $v2ray_port
	elif [[ $v2ray_transport -ge 18 ]]; then
		open_port $v2ray_port
		open_port "multiport"
	else
		open_port $v2ray_port
	fi
	# systemctl restart v2ray
	do_service restart v2ray
	backup_config

}

backup_config() {
	sed -i "18s/=1/=$v2ray_transport/; 21s/=1533/=$v2ray_port/; 24s/=$old_id/=$uuid/" $backup
	if [[ $v2ray_transport -ge 18 ]]; then
		sed -i "30s/=10000/=$v2ray_dynamic_port_start_input/; 33s/=20000/=$v2ray_dynamic_port_end_input/" $backup
	fi
	if [[ $shadowsocks ]]; then
		sed -i "42s/=/=true/; 45s/=6666/=$ssport/; 48s/=heidark.ga/=$sspass/; 51s/=chacha20-ietf/=$ssciphers/" $backup
	fi
	[[ $v2ray_transport == [45] ]] && sed -i "36s/=heidark.ga/=$domain/" $backup
	[[ $caddy ]] && sed -i "39s/=/=true/" $backup
	[[ $ban_ad ]] && sed -i "54s/=/=true/" $backup
	if [[ $is_path ]]; then
		sed -i "57s/=/=true/; 60s/=beowulf/=$path/" $backup
		sed -i "63s#=https://outlook.live.com/owa/#=$proxy_site#" $backup
	fi
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

	echo -e "\n$red input error! $none\n"

}

pause() {

	read -rsp "$(echo -e "Press $green Enter $none to continue....Or press $red Ctrl + C $noneto cancel.")" -d $'\n'
	echo
}
do_service() {
	if [[ $systemd ]]; then
		systemctl $1 $2
	else
		service $2 $1
	fi
}
show_config_info() {
	clear
	_load v2ray-info.sh
	_v2_args
	_v2_info
	_load ss-info.sh

}

install() {
	if [[ -f /usr/bin/v2ray/v2ray && -f /etc/v2ray/config.json ]] && [[ -f $backup && -d /etc/v2ray/vCross/v2ray ]]; then
		echo
		echo " Dude... V2Ray has already been installed...no need to re-install"
		echo
		echo -e " ${yellow}input ${cyan}v2ray${none} $yellow to manage V2Ray${none}"
		echo
		exit 1
	elif [[ -f /usr/bin/v2ray/v2ray && -f /etc/v2ray/config.json ]] && [[ -f /etc/v2ray/vCross_v2ray_backup.txt && -d /etc/v2ray/vCross/v2ray ]]; then
		echo
		echo "  If you'll continue to install.. Please remove the previous installation."
		echo
		echo -e " $yellow Input ${cyan}v2ray uninstall${none} $yellow to remove ${none}"
		echo
		exit 1
	fi
	v2ray_config
	blocked_hosts
	shadowsocks_config
	install_info
	# [[ $caddy ]] && domain_check
	install_v2ray
	if [[ $caddy || $v2ray_port == "80" ]]; then
		if [[ $cmd == "yum" ]]; then
			[[ $(pgrep "httpd") ]] && systemctl stop httpd
			[[ $(command -v httpd) ]] && yum remove httpd -y
		else
			[[ $(pgrep "apache2") ]] && service apache2 stop
			[[ $(command -v apache2) ]] && apt-get remove apache2* -y
		fi
	fi
	[[ $caddy ]] && install_caddy

	## bbr
	_load bbr.sh
	_try_enable_bbr

	get_ip
	config
	show_config_info
}
uninstall() {

	if [[ -f /usr/bin/v2ray/v2ray && -f /etc/v2ray/config.json ]] && [[ -f $backup && -d /etc/v2ray/vCross/v2ray ]]; then
		. $backup
		if [[ $mark ]]; then
			_load uninstall.sh
		else
			echo
			echo -e " $yellow Input ${cyan}v2ray uninstall${none} $yellow to remove${none}"
			echo
		fi

	elif [[ -f /usr/bin/v2ray/v2ray && -f /etc/v2ray/config.json ]] && [[ -f /etc/v2ray/vCross_v2ray_backup.txt && -d /etc/v2ray/vCross/v2ray ]]; then
		echo
		echo -e " $yellow Input ${cyan}v2ray uninstall${none} $yellow to remove${none}"
		echo
	else
		echo -e "
		$red Bro...It seems you hasn't installed V2Ray ....no need to remove...$none

		Note...Can only remove (vCross) V2Ray script
		" && exit 1
	fi

}

args=$1
_gitbranch=$2
[ -z $1 ] && args="online"
case $args in
online)
	#hello world
	[[ -z $_gitbranch ]] && _gitbranch="master"
	;;
local)
	local_install=true
	;;
*)
	echo
	echo -e " Your input <$red $args $none> ...can't be recognized..."
	echo
	echo -e " This script can only accept $green local / online $none"
	echo
	echo -e " Input $yellow local $none to install locally"
	echo
	echo -e " Input $yellow online $none to install online (default)"
	echo
	exit 1
	;;
esac

clear
while :; do
	echo
	echo "........... V2Ray installation & management script by vCross .........."
	echo
	echo "Ref: https://233v2.com/post/1/"
	echo
	echo "Ref Guide: https://233v2.com/post/2/"
	echo
	echo " 1. Install"
	echo
	echo " 2. Remove"
	echo
	if [[ $local_install ]]; then
		echo -e "$yellow Tips.. You have chosen to install locally ..$none"
		echo
	fi
	read -p "$(echo -e "Please choose [${magenta}1-2$none]:")" choose
	case $choose in
	1)
		install
		break
		;;
	2)
		uninstall
		break
		;;
	*)
		error
		;;
	esac
done