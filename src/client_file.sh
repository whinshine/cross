# vmess
_load vmess-config.sh
_get_client_file() {
    local _link="$(cat $v2ray_client_config | tr -d [:space:] | base64 -w0)"
    local link="https://whinshine.github.io/json.html#${_link}"
    echo
    echo "---------- V2Ray client config files -------------"
    echo
    echo -e ${cyan}$link${none}
    echo
    echo " V2Ray client user guide: https://233v2.com/post/4/"
    echo
    echo
}
