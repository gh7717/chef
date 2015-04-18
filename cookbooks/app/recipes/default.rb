#
# Cookbook Name:: app
# Recipe:: default
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
%w{wget vim htop git}.each do |packages| 
  package packages do
	action :install
  end
end
