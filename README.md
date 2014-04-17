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

Setup and provision on EC2.

    ec2-create-keypair example | sed -ne '2,$p' > ~/.ssh/example.pem
    chmod 400 ~/.ssh/example.pem

    ec2-create-group example-group -d "Example security group"
    ec2-authorize example-group -p 22 -s 0.0.0.0/0

    # Ubuntu Server 12.04 LTS
    instance="$(ec2-run-instances ami-fa9cf1ca -t m3.medium -k example -g example-group | awk '/^INSTANCE/ { print $2 }')"
    instance_host_name="$(ec2-describe-instances "$instance" | awk '/^INSTANCE/ { print $4 }')"
    ssh -i ~/.ssh/example.pem ubuntu@"$instance_host_name"
    ec2-terminate-instances "$instance"

