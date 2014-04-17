#!/bin/bash
#############################################
sed -i -e '/chef/d' /etc/hosts
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
apt-get -y install expect curl git vim

if ! [ -e chef_11.12.2-1_amd64.deb ]
then curl -O https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/12.04/x86_64/chef_11.12.2-1_amd64.deb
fi
dpkg -i chef_11.12.2-1_amd64.deb

# https://tickets.opscode.com/browse/CHEF-5211
# https://github.com/opscode/chef/pull/1375/files
sed -i.bak -e '
155 a\
        o.load_plugins
' /opt/chef/embedded/lib/ruby/gems/1.9.1/gems/chef-11.12.2/lib/chef/knife/configure.rb

mkdir -p /etc/chef-server
cp /vagrant/vm/tmp/{admin,chef-validator}.pem /etc/chef-server
chown -R vagrant:vagrant /etc/chef-server

cp /vagrant/vm/tmp/chef-node.pem /home/vagrant/.ssh
chown vagrant:vagrant /home/vagrant/.ssh/chef-node.pem
chmod 400 /home/vagrant/.ssh/chef-node.pem

rm -rf /home/vagrant/.chef
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

#############################################
apt-get -y install ruby1.9.3 build-essential libopenssl-ruby1.9.1 libssl-dev zlib1g-dev
gem install bundler -v 1.6.2

# The libgecode stuff is needed because dep-selector-libgecode does not
# compile properly as of this momement, so instead use the package install
# (which I hope is the correct 3.x version instead of the 4.x version, but I
# can't figure out how to verify that).
apt-get -y install libgecode-dev
cd /vagrant
sudo -u vagrant USE_SYSTEM_GECODE=1 bundle install --path vendor

# Shennanigans to get past the fact the chef-server in this example does not
# have an ssl cert: https://github.com/berkshelf/berkshelf#ssl-errors
mkdir -p /vagrant/.berkshelf
cat > /vagrant/.berkshelf/config.json <<DOC
{
  "ssl": {
    "verify": false
  }
}
DOC
chown -R vagrant:vagrant /vagrant/.berkshelf

#############################################
cd /vagrant/vm/tmp
apt-get install -y openjdk-7-jre unzip

if ! [ -e ec2-api-tools.zip ]
then curl -O http://s3.amazonaws.com/ec2-downloads/ec2-api-tools.zip
fi
rm -rf /usr/local/ec2
mkdir -p /usr/local/ec2
unzip ec2-api-tools.zip -d /usr/local/ec2

sed -i -e '/EC2-start/,/EC2-stop/d' /home/vagrant/.profile
cat >> /home/vagrant/.profile <<"DOC"
## EC2-start
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64/jre
export EC2_HOME=/usr/local/ec2/$(ls /usr/local/ec2)
export PATH="$PATH:$EC2_HOME/bin"
export AWS_ACCESS_KEY=your-aws-access-key-id
export AWS_SECRET_KEY=your-aws-secret-key

# Oregon (see ec2-describe-regions)
export EC2_URL=https://ec2.us-west-2.amazonaws.com
## EC2-stop
DOC
