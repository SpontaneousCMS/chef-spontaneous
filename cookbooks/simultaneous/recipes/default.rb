

ruby_version = node[:ruby][:version]

# install rbenv for root



bash "Update bashrc with rbenv settings" do
  user user
  code <<-CODE
    echo '' >> /root/.bashrc
    echo '# add rbenv settings to non-login shells' >> /root/.bashrc
    echo 'source /etc/profile.d/rbenv.sh'           >> /root/.bashrc
  CODE
  not_if "test -f /root/.bashrc && grep rbenv.sh /root/.bashrc"
end

rbenv_gem "bundler" do
  rbenv_version ruby_version
  version       node["ruby"]["bundler_version"]
  user          "root"
end

rbenv_gem "simultaneous" do
  rbenv_version ruby_version
  version       node[:simultaneous][:version]
  user          "root"
  notifies :restart, "service[simultaneous]"
end


group node[:simultaneous][:group] do
  members ["root"]
  append true
end

runit_service "simultaneous"


