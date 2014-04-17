#!/bin/bash
#############################################
sed -i -e '/chef/d' /etc/hosts
cat /vagrant/vm/config/hosts >> /etc/hosts

mkdir -p /vagrant/vm/tmp
cd /vagrant/vm/tmp
#############################################

apt-get update
apt-get -y install curl

if ! [ -e chef-server_11.0.12-1.ubuntu.12.04_amd64.deb ]
then curl -O https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/12.04/x86_64/chef-server_11.0.12-1.ubuntu.12.04_amd64.deb
fi

dpkg -i chef-server_11.0.12-1.ubuntu.12.04_amd64.deb
chef-server-ctl reconfigure
