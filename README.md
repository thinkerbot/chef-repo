# Chef-Repo

Cookbooks and examples.

## Setup

Create the server:

    vagrant up chef-server

Now that the server is set up, go to:

    https://$(grep 'chef-server.example.com' vm/config/hosts | tail -n 1 | awk '{ print $1 }')

Login as (admin, p@ssw0rd1) and regenerate the admin.pem and
chef-validator.pem files; the you will be prompted to create the admin.pem on
login and you can get the other one by looking under the clients tab and
clicking to edit the chef-validator client.

Put them into vm/tmp. Also add the identify file to ssh to the vagrant boxes
(this is analogous to getting the pem file for AWS instances).

    cp "$(vagrant ssh-config chef-node | awk '/IdentityFile/ {print $2}')" vm/tmp/chef-node.pem

Now setup the workstation and a node:

    vagrant up chef-workstation
    vagrant up chef-node

Then provisions the node from the workstation.

    vagrant ssh chef-workstation
    knife bootstrap chef-node.example.com -x vagrant -i ~/.ssh/chef-node.pem -N node1 --sudo
