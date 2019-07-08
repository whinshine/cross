_ban_bt_main() {
	if [[ $ban_bt ]]; then
		local _info="$green turned on$none"
	else
		local _info="$red turned off$none"
	fi
	_opt=''
	while :; do
		echo
		echo -e "$yellow 1. $none turn on BT blocking"
		echo
		echo -e "$yellow 2. $none turn off BT blocking"
		echo
		echo -e "current BT blocking status: $_info"
		echo
		read -p "$(echo -e "Please choose [${magenta}1-2$none]:")" _opt
		if [[ -z $_opt ]]; then
			error
		else
			case $_opt in
			1)
				if [[ $ban_bt ]]; then
					echo
					echo -e " Bro... no need to modify(Current bt blocking status: $_info) "
					echo
				else
					echo
					echo
					echo -e "$yellow  BT blocking = $cyan turn on$none"
					echo "----------------------------------------------------------------"
					echo
					pause
					backup_config +bt
					ban_bt=true
					config
					echo
					echo
					echo -e "$green  BT blocking has been turned on...$none"
					echo
				fi
				break
				;;
			2)
				if [[ $ban_bt ]]; then
					echo
					echo
					echo -e "$yellow  BT blocking = $cyan turn off$none"
					echo "----------------------------------------------------------------"
					echo
					pause
					backup_config -bt
					ban_bt=''
					config
					echo
					echo
					echo -e "$red  BT blocking has been turned off...$none"
					echo
				else
					echo
					echo -e " Bro...no need to modify(Current bt blocking status: $_info)"
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
