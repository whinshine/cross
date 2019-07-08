_get_latest_version() {
	v2ray_latest_ver="$(curl -H 'Cache-Control: no-cache' -s https://api.github.com/repos/v2ray/v2ray-core/releases/latest | grep 'tag_name' | cut -d\" -f4)"

	if [[ ! $v2ray_latest_ver ]]; then
		echo
		echo -e " $redfail to retrieve latest V2Ray version!!!$none"
		echo
		echo -e " Please try to execute : $green echo 'nameserver 8.8.8.8' >/etc/resolv.conf $none"
		echo
		echo " And then re-run the script..."
		echo
		exit 1
	fi
}

_download_v2ray_file() {
	_get_latest_version
	[[ -d /tmp/v2ray ]] && rm -rf /tmp/v2ray
	mkdir -p /tmp/v2ray
	v2ray_tmp_file="/tmp/v2ray/v2ray.zip"
	v2ray_download_link="https://github.com/v2ray/v2ray-core/releases/download/$v2ray_latest_ver/v2ray-linux-${v2ray_bit}.zip"

	if ! wget --no-check-certificate -O "$v2ray_tmp_file" $v2ray_download_link; then
		echo -e "
        $red fail to download V2Ray..Maybe your VPS network has some problem...Please retry...$none
        " && exit 1
	fi

	unzip $v2ray_tmp_file -d "/tmp/v2ray/"
	mkdir -p /usr/bin/v2ray
	cp -f "/tmp/v2ray/v2ray" "/usr/bin/v2ray/v2ray"
	chmod +x "/usr/bin/v2ray/v2ray"
	echo "alias v2ray=$_v2ray_sh" >>/root/.bashrc
	cp -f "/tmp/v2ray/v2ctl" "/usr/bin/v2ray/v2ctl"
	chmod +x "/usr/bin/v2ray/v2ctl"
}

_install_v2ray_service() {
	if [[ $systemd ]]; then
		cp -f "/tmp/v2ray/systemd/v2ray.service" "/lib/systemd/system/"
		sed -i "s/on-failure/always/" /lib/systemd/system/v2ray.service
		systemctl enable v2ray
	else
		apt-get install -y daemon
		cp "/tmp/v2ray/systemv/v2ray" "/etc/init.d/v2ray"
		chmod +x "/etc/init.d/v2ray"
		update-rc.d -f v2ray defaults
	fi
}

_update_v2ray_version() {
	_get_latest_version
	if [[ $v2ray_ver != $v2ray_latest_ver ]]; then
		echo
		echo -e " $green Yeah...A new release has been found...Try to update it...$none"
		echo
		_download_v2ray_file
		do_service restart v2ray
		echo
		echo -e " $green Succeed to update...Current V2Ray version: ${cyan}$v2ray_latest_ver$none"
		echo
		echo -e " $yellow Tips: to avoid unkown issues...had better to keep V2Ray client version alignment with V2Ray server version$none"
		echo
	else
		echo
		echo -e " $green No new release found....$none"
		echo
	fi
}

_mkdir_dir() {
	mkdir -p /var/log/v2ray
	mkdir -p /etc/v2ray
}
