command_exists() {
	if command -v $1 >/dev/null 2>&1; then
		return
	fi

	false
}

apt_install() {
	sudo apt install -y $@
}

is_apt_pkg_installed() {
	[[ "installed" == $(dpkg -s ${1} &>/dev/null | cat | grep -i status &>/dev/null | cat | awk '{print $NF}') ]]
}
