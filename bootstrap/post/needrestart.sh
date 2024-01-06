#! /bin/env bash

sudo sed -i "/#\$nrconf{restart} = 'a';/s/.*/\$nrconf{restart} = 'i';/" /etc/needrestart/needrestart.conf
