#!/bin/bash
#############################################
set -e '/chef/d' /etc/hosts
cat /vagrant/vm/config/hosts >> /etc/hosts
