_view_mtproto_info() {
	if [[ $mtproto ]]; then
		_mtproto_info
	else
		_mtproto_ask
	fi
}
_mtproto_info() {
	[[ -z $ip ]] && get_ip
	echo
	echo "---------- Telegram MTProto config info -------------"
	echo
	echo -e "$yellow (Hostname) = $cyan${ip}$none"
	echo
	echo -e "$yellow (Port) = $cyan$mtproto_port$none"
	echo
	echo -e "$yellow (Secret) = $cyan$mtproto_secret$none"
	echo
	echo -e "$yellow Telegram proxy URL = ${cyan}https://t.me/proxy?server=${ip}&port=${mtproto_port}&secret=${mtproto_secret}$none"
	echo
}
_mtproto_main() {
	if [[ $mtproto ]]; then

		while :; do
			echo
			echo -e "$yellow 1. $none view Telegram MTProto config info"
			echo
			echo -e "$yellow 2. $none modify Telegram MTProto port"
			echo
			echo -e "$yellow 3. $none modify Telegram MTProto secret"
			echo
			echo -e "$yellow 4. $none turn off Telegram MTProto"
			echo
			read -p "$(echo -e "Please choose [${magenta}1-4$none]:")" _opt
			if [[ -z $_opt ]]; then
				error
			else
				case $_opt in
				1)
					_mtproto_info
					break
					;;
				2)
					change_mtproto_port
					break
					;;
				3)
					change_mtproto_secret
					break
					;;
				4)
					disable_mtproto
					break
					;;
				*)
					error
					;;
				esac
			fi

		done
	else
		_mtproto_ask
	fi
}
_mtproto_ask() {
	echo
	echo
	echo -e " $red Dude...You didn't config Telegram MTProto $none...But you can do it now ^_^"
	echo
	echo
	new_mtproto_secret="dd$(date | md5sum | cut -c-30)"
	while :; do
		echo -e "Wanna config ${yellow}Telegram MTProto${none} [${magenta}Y/N$none]"
		read -p "$(echo -e "(default [${cyan}N$none]):") " new_mtproto
		[[ -z "$new_mtproto" ]] && new_mtproto="n"
		if [[ "$new_mtproto" == [Yy] ]]; then
			echo
			mtproto=true
			mtproto_port_config
			pause
			open_port $new_mtproto_port
			backup_config +mtproto
			mtproto_port=$new_mtproto_port
			mtproto_secret=$new_mtproto_secret
			config
			clear
			_mtproto_info
			break
		elif [[ "$new_mtproto" == [Nn] ]]; then
			echo
			echo -e " $green Candel to config Telegram MTProto ....$none"
			echo
			break
		else
			error
		fi

	done
}
disable_mtproto() {
	echo

	while :; do
		echo -e "Wanna turn off ${yellow}Telegram MTProto${none} [${magenta}Y/N$none]"
		read -p "$(echo -e "(default [${cyan}N$none]):") " y_n
		[[ -z "$y_n" ]] && y_n="n"
		if [[ "$y_n" == [Yy] ]]; then
			echo
			echo
			echo -e "$yellow turn off Telegram MTProto = $cyan Yes$none"
			echo "----------------------------------------------------------------"
			echo
			pause
			backup_config -mtproto
			del_port $mtproto_port
			mtproto=''
			config
			echo
			echo
			echo
			echo -e "$green Telegram MTProto has been turned off...$none"
			echo
			break
		elif [[ "$y_n" == [Nn] ]]; then
			echo
			echo -e " $green Cancel to turn off Telegram MTProto ....$none"
			echo
			break
		else
			error
		fi

	done
}
mtproto_port_config() {
	local random=$(shuf -i20001-65535 -n1)
	echo
	while :; do
		echo -e "Please input "$yellow"Telegram MTProto"$none" port ["$magenta"1-65535"$none"], can't be same with "$yellow"V2Ray"$none" port"
		read -p "$(echo -e "(default port: ${cyan}${random}$none):") " new_mtproto_port
		[ -z "$new_mtproto_port" ] && new_mtproto_port=$random
		case $new_mtproto_port in
		$v2ray_port)
			echo
			echo " Can't be same with V2Ray port...."
			error
			;;
		[1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
			if [[ $v2ray_transport == [45] ]]; then
				local tls=ture
			fi
			if [[ $tls && $new_mtproto_port == "80" ]] || [[ $tls && $new_mtproto_port == "443" ]]; then
				echo
				echo -e "由于你已选择了 "$green"WebSocket + TLS $none或$green HTTP/2"$none" 传输协议."
				echo
				echo -e "所以不能选择 "$magenta"80"$none" 或 "$magenta"443"$none" 端口"
				error
			elif [[ $dynamicPort ]] && [[ $v2ray_dynamicPort_start == $new_mtproto_port || $v2ray_dynamicPort_end == $new_mtproto_port ]]; then
				echo
				echo -e " 抱歉，此端口和 V2Ray 动态端口 冲突，当前 V2Ray 动态端口范围为：${cyan}$port_range${none}"
				error
			elif [[ $dynamicPort ]] && [[ $v2ray_dynamicPort_start -lt $new_mtproto_port && $new_mtproto_port -le $v2ray_dynamicPort_end ]]; then
				echo
				echo -e " 抱歉，此端口和 V2Ray 动态端口 冲突，当前 V2Ray 动态端口范围为：${cyan}$port_range${none}"
				error
			elif [[ $shadowsocks && $new_mtproto_port == $ssport ]]; then
				echo
				echo -e "抱歉, 此端口跟 Shadowsocks 端口冲突...当前 Shadowsocks 端口: ${cyan}$ssport$none"
				error
			elif [[ $socks && $new_mtproto_port == $socks_port ]]; then
				echo
				echo -e "抱歉, 此端口跟 Socks 端口冲突...当前 Socks 端口: ${cyan}$socks_port$none"
				error
			else
				echo
				echo
				echo -e "$yellow Telegram MTProto 端口 = $cyan$new_mtproto_port$none"
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
change_mtproto_secret() {
	new_mtproto_secret="dd$(date | md5sum | cut -c-30)"
	echo
	while :; do
		read -p "$(echo -e "是否更改 ${yellow}Telegram MTProto 密钥${none} [${magenta}Y/N$none]"): " y_n
		[ -z "$y_n" ] && error && continue
		case $y_n in
		n | N)
			echo
			echo -e " 已取消更改.... "
			echo
			break
			;;
		y | Y)
			echo
			echo
			echo -e "$yellow 更改 Telegram MTProto 密钥 = $cyan是$none"
			echo "----------------------------------------------------------------"
			echo
			pause
			backup_config mtproto_secret
			mtproto_secret=$new_mtproto_secret
			config
			clear
			_mtproto_info
			break
			;;
		esac
	done
}
change_mtproto_port() {
	echo
	while :; do
		echo -e "请输入新的 "$yellow"Telegram MTProto"$none" 端口 ["$magenta"1-65535"$none"]"
		read -p "$(echo -e "(当前端口: ${cyan}${mtproto_port}$none):") " new_mtproto_port
		[ -z "$new_mtproto_port" ] && error && continue
		case $new_mtproto_port in
		$mtproto_port)
			echo
			echo " 不能跟当前端口一毛一样...."
			error
			;;
		$v2ray_port)
			echo
			echo " 不能和 V2Ray 端口一毛一样...."
			error
			;;
		[1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
			if [[ $v2ray_transport == [45] ]]; then
				local tls=ture
			fi
			if [[ $tls && $new_mtproto_port == "80" ]] || [[ $tls && $new_mtproto_port == "443" ]]; then
				echo
				echo -e "由于你已选择了 "$green"WebSocket + TLS $none或$green HTTP/2"$none" 传输协议."
				echo
				echo -e "所以不能选择 "$magenta"80"$none" 或 "$magenta"443"$none" 端口"
				error
			elif [[ $dynamicPort ]] && [[ $v2ray_dynamicPort_start == $new_mtproto_port || $v2ray_dynamicPort_end == $new_mtproto_port ]]; then
				echo
				echo -e " 抱歉，此端口和 V2Ray 动态端口 冲突，当前 V2Ray 动态端口范围为：${cyan}$port_range${none}"
				error
			elif [[ $dynamicPort ]] && [[ $v2ray_dynamicPort_start -lt $new_mtproto_port && $new_mtproto_port -le $v2ray_dynamicPort_end ]]; then
				echo
				echo -e " 抱歉，此端口和 V2Ray 动态端口 冲突，当前 V2Ray 动态端口范围为：${cyan}$port_range${none}"
				error
			elif [[ $shadowsocks && $new_mtproto_port == $ssport ]]; then
				echo
				echo -e "抱歉, 此端口跟 Shadowsocks 端口冲突...当前 Shadowsocks 端口: ${cyan}$ssport$none"
				error
			elif [[ $socks && $new_mtproto_port == $socks_port ]]; then
				echo
				echo -e "抱歉, 此端口跟 Socks 端口冲突...当前 Socks 端口: ${cyan}$socks_port$none"
				error
			else
				echo
				echo
				echo -e "$yellow socks 端口 = $cyan$new_mtproto_port$none"
				echo "----------------------------------------------------------------"
				echo
				pause
				backup_config mtproto_port
				mtproto_port=$new_mtproto_port
				config
				clear
				_mtproto_info
				break
			fi
			;;
		*)
			error
			;;
		esac

	done

}
