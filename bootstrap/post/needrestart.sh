#! /bin/env bash

needrestart_file=/etc/needrestart/needrestart.conf
if [[ -f $needrestart_file ]]; then
	sudo sed -i "/#\$nrconf{restart} = 'i';/s/.*/\$nrconf{restart} = 'a';/" $needrestart_file
fi

unset needrestart_file
