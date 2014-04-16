#!/bin/bash
#############################################
set -e '/chef/d' /etc/hosts
cat /vagrant/vm/config/hosts >> /etc/hosts

mkdir -p /vagrant/vm/tmp
cd /vagrant/vm/tmp

if ! [ -e /vagrant/vm/tmp/admin.pem ] || 
   ! [ -e /vagrant/vm/tmp/chef-validator.pem ] ||
   ! [ -e /vagrant/vm/tmp/chef-node.pem ]
then
printf "%s" "\

  Missing certificates (ex: vm/tmp/admin.pem).  Please follow
  the instructions in the README and try again.

" >&2
  exit 1
fi
#############################################

apt-get update
apt-get -y install expect curl git

if ! [ -e chef_11.12.2-1_amd64.deb ]
then curl -O https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/12.04/x86_64/chef_11.12.2-1_amd64.deb
fi
sudo dpkg -i chef_11.12.2-1_amd64.deb

# https://tickets.opscode.com/browse/CHEF-5211
# https://github.com/opscode/chef/pull/1375/files
sudo sed -i.bak -e '
155 a\
        o.load_plugins
' /opt/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-11.12.2/lib/chef/knife/configure.rb

mkdir -p /etc/chef-server
cp /vagrant/vm/tmp/{admin,chef-validator}.pem /etc/chef-server
chown -R vagrant:vagrant /etc/chef-server

cp /vagrant/vm/tmp/chef-node.pem /home/vagrant/.ssh
chown vagrant:vagrant /home/vagrant/.ssh/chef-node.pem
chmod 600 /home/vagrant/.ssh/chef-node.pem

rm -f /home/vagrant/.chef/knife.rb
sudo -i -u vagrant expect - <<DOC
spawn knife configure --initial
expect -ex "Where should I put the config file" { send "/home/vagrant/.chef/knife.rb\r" }
expect -ex "Please enter the chef server URL:" { send "https://chef-server.example.com\r" }
expect -ex "Please enter a name for the new user:" { send "vagrant\r" }
expect -ex "Please enter the existing admin name:" { send "admin\r" }
expect -ex "Please enter the location of the existing admin's private key:" { send "/etc/chef-server/admin.pem\r" }
expect -ex "Please enter the validation clientname:" { send "chef-validator\r" }
expect -ex "Please enter the location of the validation key:" { send "/etc/chef-server/chef-validator.pem\r" }
expect -ex "Please enter the path to a chef repository (or leave blank):" { send "/vagrant\r" }
expect -ex "Please enter a password for the new user:" { send "sup3rsecure\r" }
expect -ex "Configuration file written"
wait
DOC
