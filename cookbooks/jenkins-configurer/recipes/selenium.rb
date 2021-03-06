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

package 'xvfb'

cookbook_file '/etc/init.d/xvfb' do
  action :create
  mode   '0755'
end

execute 'add xvfb to the set of init scripts' do
  command 'update-rc.d xvfb defaults'
end

service 'xvfb' do
  action  :start
end

file "#{node['jenkins-configurer']['home']}/.bashrc" do
  action :create
  not_if { ::File.exists?("#{node['jenkins-configurer']['home']}/.bashrc")}
end

ruby_block "export_display_on_bashrc" do
  block do
    file = Chef::Util::FileEdit.new("#{node['jenkins-configurer']['home']}/.bashrc")
    file.search_file_delete_line(/export DISPLAY/)
    file.write_file
    file.insert_line_if_no_match(/export DISPLAY=0:1/, "export DISPLAY=0:1")
    file.write_file
  end
end

package 'mediainfo' 
package 'firefox'

package 'libxss1'
package 'xdg-utils'

package 'wget'
package 'libpango1.0-0'
package 'libappindicator1'

# Install Google Chrome

#if node['kernel']['machine'] == 'x86_64' then
#  google_package_name = 'google-chrome-stable_current_amd64.deb'
#else
#  google_package_name = 'google-chrome-stable_current_i386.deb'
#end

package 'google-chrome-stable'


#execute "wget https://dl.google.com/linux/direct/#{google_package_name}" do
#  not_if { ::File.exists?(google_package_name)}
#end

#execute "install google chrome" do 
#  command "dpkg -i #{google_package_name} && touch /tmp/google-chrome"
#  not_if { ::File.exists?("/tmp/google-chrome")}
#end



# Kurento Media Server
apt_repository 'kurento' do
  uri          'http://ppa.launchpad.net/kurento/kurento/ubuntu/'
  distribution node['lsb']['codename']
  components   ['main']
  keyserver    'keyserver.ubuntu.com'
  key          '6B5278DE'
end

ruby_block "add_kurento_repo" do
  block do
    file = Chef::Util::FileEdit.new("/etc/apt/sources.list")
    file.insert_line_if_no_match("deb http://ubuntu.kurento.org repo/", "deb http://ubuntu.kurento.org repo/")
    file.write_file  end
end

package 'rabbitmq-server'

package 'kurento'
# %w{devscripts cmake libthrift-dev thrift-compiler gstreamer1.0* libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libnice-dev gtk-doc-tools cmake libglibmm-2.4-dev uuid-dev libevent-dev libboost-dev libboost-system-dev libboost-filesystem-dev libboost-test-dev libsctp-dev libopencv-dev autoconf libjsoncpp-dev libtool libsoup2.4-dev tesseract-ocr-dev tesseract-ocr-eng libgnutls28-dev gnutls-bin libvpx-dev librabbitmq-dev ktool-rom-processor kurento rabbitmq-server}.each do |pkg|
#   package pkg
# end

# Required to test KWS
package 'software-properties-common'
package 'python-software-properties'

apt_repository 'nodejs' do
  uri          'http://ppa.launchpad.net/chris-lea/node.js/ubuntu'
  distribution node['lsb']['codename']
  components   ['main']
  keyserver    'keyserver.ubuntu.com'
  key          'C7917B12'
end

package 'g++'
package 'make'
package 'nodejs'

# Required build ktool-rom-processor debian package
%w{debhelper cdbs default-jdk maven-debian-helper libmaven-assembly-plugin-java libmaven-compiler-plugin-java libfreemarker-java libgoogle-gson-java libslf4j-java libcommons-cli-java}.each do |pkg|
  package pkg
end

package 'maven'

execute 'update-alternatives --set mvn /usr/share/maven/bin/mvn'

file "/etc/cron.hourly/ntpdate" do
  content "ntpdate ntp.ubuntu.com"
  mode 755
  action :create
end

subversion "Checkout test files" do
  repository "http://files.kurento.org/svn/kurento"
  destination "#{node['jenkins-configurer']['home']}/test-files"
  revision "HEAD"
#  user node['jenkins-configurer']['user']
#  group node['jenkins-configurer']['group']
  action :checkout
end
