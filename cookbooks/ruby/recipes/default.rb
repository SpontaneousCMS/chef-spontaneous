require_recipe "ruby_build"

ruby_version = node[:ruby][:version]

ruby_build_ruby ruby_version do
  prefix_path File.join(node[:ruby][:ruby_root], ruby_version)
  action      :install
end

sites = node[:sites]

node["ruby"]["users"] = [
  { 'user' => 'root',
    'home' => '/root',
    'group' => "root" }
].concat sites.map { |site| { 'user' => site[:login], 'home' => "/home/#{site[:login]}", "group" => site[:login] } }

p node["ruby"]["users"]

node['rbenv']['user_installs'] = node["ruby"]["users"]

require_recipe 'rbenv::user_install'

Array(node['ruby']['users']).each do |rb_user|
  user = rb_user["user"]
  home = rb_user["home"]
  group = rb_user["group"]

  rbenv_user user do
    home home
  end

  rbenv_dir =  "#{home}/.rbenv"


  link "#{rbenv_dir}/versions/#{ruby_version}" do
    to File.join(node[:ruby][:ruby_root], ruby_version)
  end

  rbenv_rehash "Rehashing root rbenv" do
    user user
  end


  rbenv_global ruby_version do
    user user
  end
end
