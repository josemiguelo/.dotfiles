create_file() {
	[ ! -f $1 ] && {
		log "creating $1 file..."
		touch $1
	}
}
