
# Cookbook Name:: chef-server
# Recipe:: default
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
include_recipe "update"
include_recipe "app"
#include_recipe "chef-solo-search"

package_url_chef = node['chef-server']['chef']['url']
package_name_chef = ::File.basename(package_url_chef)
package_local_path_chef = "#{Chef::Config[:file_cache_path]}/#{package_name_chef}"

package_url_sdk = node['chef-server']['sdk']['url']
package_name_sdk = ::File.basename(package_url_sdk)
package_local_path_sdk = "#{Chef::Config[:file_cache_path]}/#{package_name_sdk}"


admin_user = search(:admins).first
organization = search(:organizations).first
#admin_users = data_bag('admins')
#organizations = data_bag('organization')
#admin_users.first do |user_info|
#	admin_user = data_bag_item('admin_users', user_info)
#end
#organizations.first do |organization_info|
#	organization = data_bag_item('organizations', organization_info)
#end
key_directory = node['chef-server']['key_directory']

remote_file package_local_path_chef do
  source package_url_chef
end
package package_name_chef do
  source package_local_path_chef
  provider Chef::Provider::Package::Dpkg
  notifies :run, 'execute[reconfigure-chef-server]', :immediately
end
execute 'reconfigure-chef-server' do
  command 'chef-server-ctl reconfigure'
  action :nothing
end
execute 'user-create' do
	command "chef-server-ctl user-create #{admin_user['id']} #{admin_user['first_name']} #{admin_user['last_name']} #{admin_user['email']} #{admin_user['password']} -f #{key_directory}/#{admin_user['id']}.pem"
    not_if "chef-server-ctl user-list | grep #{admin_user['id']}"
end
execute 'org-create' do
	command "chef-server-ctl org-create #{organization['id']} #{organization['long_name']} --association_user #{admin_user['id']} -f  #{key_directory}/#{organization["id"]}"
    not_if "chef-server-ctl org-list | grep #{organization['id']}"
end

remote_file package_local_path_sdk do
	source package_url_sdk
end
package package_name_sdk do
	source package_local_path_sdk
	provider Chef::Provider::Package::Dpkg
	notifies :run, 'execute[chef-verify]', :immediately
end
execute 'chef-verify' do
	command 'chef verify'
    action :nothing
end	
directory "/root/.chef" do
	action :create
end
directory "/root/cookbooks" do
   action :create
end
template "/root/.chef/knife.rb" do
	source 'knife.erb'
	mode '0440'
	owner 'root'
	group 'root'
	variables({
		:loglevel => node['knife']['loglevel'],
		:user     => admin_user['id'],
		:org      => organization['id'],
		:dir	  => key_directory,
		:fqdn	  => node['fqdn']
	})
    notifies :run, 'execute[knife-fetch]', :immediately
end
execute 'knife-fetch' do
    command "knife ssl fetch"
    action :nothing
end
