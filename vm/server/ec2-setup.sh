#!/bin/bash
sudo apt-get update
sudo apt-get -y install curl

curl -O https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/12.04/x86_64/chef-server_11.0.12-1.ubuntu.12.04_amd64.deb
sudo dpkg -i chef-server_11.0.12-1.ubuntu.12.04_amd64.deb
sudo chef-server-ctl reconfigure
