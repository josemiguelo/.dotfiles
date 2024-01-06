#! /bin/env bash

yq_binary=$BOOTSTRAP_DIR/bin/yq
if [[ -f $yq_binary ]]; then
	warn "yq has already been installed"
else
	# TODO: linux linux amd64 is hardcoded. adapt to other platforms/oses
	mkdir -p $BOOTSTRAP_DIR/bin
	warn "downloading yq binary"
	wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O $yq_binary && chmod +x $yq_binary
fi
