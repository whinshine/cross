_download_caddy_file() {
	caddy_tmp="/tmp/install_caddy/"
	caddy_tmp_file="/tmp/install_caddy/caddy.tar.gz"
	[[ -d $caddy_tmp ]] && rm -rf $caddy_tmp
	local caddy_download_link="https://caddyserver.com/download/linux/${caddy_arch}?license=personal"

	mkdir -p $caddy_tmp

	if ! wget --no-check-certificate -O "$caddy_tmp_file" $caddy_download_link; then
		echo -e "$red fail to download!$none" && exit 1
	fi

	tar zxf $caddy_tmp_file -C $caddy_tmp
	cp -f ${caddy_tmp}caddy /usr/local/bin/

	if [[ ! -f /usr/local/bin/caddy ]]; then
		echo -e "$red fail to install Caddy!$none" && exit 1
	fi
}
_install_caddy_service() {
	setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/caddy

	if [[ $systemd ]]; then
		cp -f ${caddy_tmp}init/linux-systemd/caddy.service /lib/systemd/system/
		# sed -i "s/www-data/root/g" /lib/systemd/system/caddy.service
		sed -i "/on-abnormal/a RestartSec=3" /lib/systemd/system/caddy.service
		sed -i "s/on-abnormal/always/" /lib/systemd/system/caddy.service
		systemctl enable caddy
	else
		cp -f ${caddy_tmp}init/linux-sysvinit/caddy /etc/init.d/caddy
		# sed -i "s/www-data/root/g" /etc/init.d/caddy
		chmod +x /etc/init.d/caddy
		update-rc.d -f caddy defaults
	fi

	mkdir -p /etc/ssl/caddy

	if [ -z "$(grep www-data /etc/passwd)" ]; then
		useradd -M -s /usr/sbin/nologin www-data
	fi
	chown -R www-data.www-data /etc/ssl/caddy

	mkdir -p /etc/caddy/

	## create sites dir
	mkdir -p /etc/caddy/sites
}