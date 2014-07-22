#
# Cookbook Name:: jenkins-configurer
# Recipe:: default
#
# Copyright 2014, Kurento
#
# Licensed under the Lesser GPL, Version 2.1 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.gnu.org/licenses/lgpl-2.1.html
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

user node['jenkins-configurer']['user'] do
  home node['jenkins-configurer']['home']
  supports :manage_home => true
end

group node['jenkins-configurer']['group'] do
  members node['jenkins-configurer']['user']
end

ruby_block "add_jenkins_user_to_sudoers" do
  block do
    file = Chef::Util::FileEdit.new("/etc/sudoers")
    file.insert_line_if_no_match("/jenkins    ALL = NOPASSWD:SETENV:  /usr/bin/apt-get, /etc/init.d/kurento, /bin/kill, /usr/bin/killall, /bin/netstat, /var/lib/jenkins/kurento-media-connector/support-files/kmf-media-connector.sh/", "jenkins    ALL = NOPASSWD:SETENV:  /usr/bin/apt-get, /etc/init.d/kurento, /bin/kill, /usr/bin/killall, /bin/netstat, /var/lib/jenkins/kurento-media-connector/support-files/kmf-media-connector.sh")
    file.write_file
  end
end

directory "#{node['jenkins-configurer']['home']}/.ssh" do
  owner node['jenkins-configurer']['user']
  group node['jenkins-configurer']['group']
  mode 0600
  action :create
end

file "#{node['jenkins-configurer']['home']}/.ssh/id_rsa" do
  owner node['jenkins-configurer']['user']
  group node['jenkins-configurer']['group']
  content data_bag_item('users', 'jenkins')['ssh_private_key']
  mode 0600
  action :create
end

if not ::File.exists?("#{node['jenkins-configurer']['home']}/.ssh/config") then
  file "#{node['jenkins-configurer']['home']}/.ssh/config" do
    content "StrictHostKeyChecking no"
    action :create
  end
else
  ruby_block "disable_host_key_verification" do
    block do
      file = Chef::Util::FileEdit.new("#{node['jenkins-configurer']['home']}/.ssh/config")
      file.insert_line_if_no_match("/StrictHostKeyChecking no/", "StrictHostKeyChecking no")
      file.write_file
    end
  end
end

include_recipe 'git_user'

git_user node['jenkins-configurer']['user'] do
  login     node['jenkins-configurer']['user']
  home      node['jenkins-configurer']['home']
  full_name node['jenkins-configurer']['user']
  email     node['jenkins-configurer']['email']
end

ssh_known_hosts_entry 'ci.kurento.org'

include_recipe 'ssh-keys'

# Enable signing maven artifacts with gnupg
execute "gnupg signing credentials" do
  command "sudo -u #{node['jenkins-configurer']['user']} -H scp -r #{node['jenkins-configurer']['user']}@#{node['jenkins-configurer']['master-host']}:.gnupg #{node['jenkins-configurer']['home']}"
end

package "xmlstarlet"

# Only available since Ubuntu 14.04 Trusty Tahr
if platform?("ubuntu")
  if node['platform_version'] == "14.04"
    package "jshon"
  end
end

ruby_block "disable_ipv6" do
  block do
    file = Chef::Util::FileEdit.new("/etc/sysctl.conf")
    file.insert_line_if_no_match("/net.ipv6.conf.all.disable_ipv6 = 1/", "net.ipv6.conf.all.disable_ipv6 = 1")
    file.write_file
  end
end


