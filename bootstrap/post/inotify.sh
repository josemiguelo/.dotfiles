#! /bin/env bash

sudo sed -i '/fs.inotify.max_user_watches=/d' /etc/sysctl.conf
echo fs.inotify.max_user_watches=786420 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
