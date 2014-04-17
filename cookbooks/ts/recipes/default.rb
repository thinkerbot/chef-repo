#
# Cookbook Name:: ts
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

git "#{Chef::Config[:file_cache_path]}/ts" do
  repository node[:ts][:git_repository]
  revision node[:ts][:git_revision]
  action :sync
end

link "/usr/local/bin/ts" do
  to "#{Chef::Config[:file_cache_path]}/ts/bin/ts"
end
