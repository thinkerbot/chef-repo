# Chef-Repo

Cookbooks and examples.

## Setup

Create the server:

    vagrant up chef-server

Now that the server is set up, go to `https://192.168.33.8`, login as (admin,
p@ssw0rd1) and regenerate the admin.pem and chef-validator.pem files; the you
will be prompted to create the admin.pem on login and you can get the other
one by looking under the clients tab and clicking to edit the chef-validator
client.

Put them into vm/tmp. Also add the identify file to ssh to the vagrant boxes
(this is analogous to getting the pem file for AWS instances).

    cp "$(vagrant ssh-config chef-node | awk '/IdentityFile/ {print $2}')" vm/tmp/chef-node.pem

Now setup the workstation and a node:

    vagrant up chef-workstation
    vagrant up chef-node

Then provisions the node from the workstation.

    vagrant ssh chef-workstation
    knife bootstrap chef-node.example.com -x vagrant -i ~/.ssh/chef-node.pem -N node1 --sudo

## Example

Following the instructions
[here](https://learnchef.opscode.com/starter-use-cases/multi-node-ec2/) (but
locally on the Vagrant virtual machines)...

    vagrant ssh chef-workstation
    cd /vagrant
    bundle exec berks
    bundle exec berks upload
    knife bootstrap chef-node.example.com -x vagrant -i ~/.ssh/chef-node.pem -N node1 --sudo --run-list "role[ts]"

Note that to get the upload to succeed you have to modify the following file
after `berks`. See https://github.com/berkshelf/berkshelf/issues/1019

    [~/.berkshelf/cookbooks/ulimit-0.3.2/metadata.json]
    ...
    "platforms": {
      "debian": ">= 0.0.0",
      "fedora": ">= 0.0.0",
      "centos": ">= 0.0.0",
      "ubuntu": ">= 0.0.0",
      "suse": ">= 0.0.0",
      "redhat": ">= 0.0.0"
    }
    ...

To check it works:

    echo stats | nc chef-node.example.com 11211

## Example (ts)

An example of a custom cookbook:

    knife cookbook upload ts
    knife bootstrap chef-node.example.com -x vagrant -i ~/.ssh/chef-node.pem -N node3 --sudo --run-list "role[ts]"

To check it works:

    vagrant ssh chef-node
    ts -h

## Example (EC2)

Setup and provision chef-server on EC2.

    vagrant ssh chef-workstation

    ec2-create-keypair example | sed -ne '2,$p' > ~/.ssh/example.pem
    chmod 400 ~/.ssh/example.pem

    ec2-create-group example-group -d "Example security group"
    ec2-authorize example-group -p 22 -s 0.0.0.0/0
    ec2-authorize example-group -p 443 -s 0.0.0.0/0

    # Ubuntu Server 12.04 LTS
    server="$(ec2-run-instances ami-fa9cf1ca -t m3.medium -k example -g example-group | awk '/^INSTANCE/ { print $2 }')"
    server_hostname="$(ec2-describe-instances "$server" | awk '/^INSTANCE/ { print $4 }')"

    # Set FQDN because the server needs it, even if you go by IP via knife/browser
    ssh -i ~/.ssh/example.pem ubuntu@"$server_hostname" -- <<DOC
    echo $server_hostname > hostname
    sudo mv hostname /etc/hostname
    sudo locale-gen en_US
    DOC
    ec2-reboot-instances "$server"

    ssh -i ~/.ssh/example.pem ubuntu@"$server_hostname" < /vagrant/vm/server/ec2-setup.sh

    # Open the url printed by the following, then fetch and store admin.pem and chef-validator.pem as above
    server_url="$(ruby -e 'ARGV[0] =~ /ec2-(.*?)\./; puts "https://" + $1.tr("-",".")' "$server_hostname")"
    echo "$server_url"

    # Install certs
    cp /vagrant/vm/tmp/{admin,chef-validator}.pem /etc/chef-server
    rm -rf /home/vagrant/.chef
    expect - <<DOC
    spawn knife configure --initial
    expect -ex "Where should I put the config file" { send "/home/vagrant/.chef/knife.rb\r" }
    expect -ex "Please enter the chef server URL:" { send "$server_url\r" }
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

Now make a node:

    cd /vagrant
    bundle exec berks upload
    knife cookbook upload ts
    knife role from file roles/ts.rb
    knife role from file roles/memcached.rb

    # Ubuntu Server 12.04 LTS
    client="$(ec2-run-instances ami-fa9cf1ca -t m3.medium -k example -g example-group | awk '/^INSTANCE/ { print $2 }')"
    client_hostname="$(ec2-describe-instances "$client" | awk '/^INSTANCE/ { print $4 }')"

    knife bootstrap "$client_hostname" -x ubuntu -i ~/.ssh/example.pem -N node1 --sudo --run-list "role[ts]"
    knife bootstrap "$client_hostname" -x ubuntu -i ~/.ssh/example.pem -N node1 --sudo --run-list "role[memcached]"

Verify it worked:

    ec2-authorize example-group -p 11211 -s 0.0.0.0/0
    ssh -i ~/.ssh/example.pem ubuntu@"$client_hostname" -- 'ts -h'
    echo stats | nc "$client_hostname" 11211

Later:

    ec2-terminate-instances "$server"

See also:

* https://learnchef.opscode.com/legacy/starter-use-cases/multi-node-ec2/
