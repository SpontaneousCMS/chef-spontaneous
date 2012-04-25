package 'uuid-dev'
require_recipe 'ruby-shadow'


ruby_version = node[:ruby][:version]

sites = node[:sites]

# node['rbenv']['user_installs'] = sites.map { |site| { 'user' => site[:login], 'home' => "/home/#{site[:login]}" } }
#
# require_recipe 'rbenv::user_install'

# link "/usr/bin/ruby" do
#   owner "root"
#   group "root"
#   to "/usr/bin/ruby1.8"
# end


# bash "Install #{ruby_version}" do
#   user "root"
#   code "su -c 'rvm install #{ruby_version}' - root"
#   not_if "su -c 'rvm list' - root | grep #{ruby_version}"
# end
# rvm_ruby ruby_version do
#   action :install
# end

# bash "Make #{ruby_version} the default for root" do
#   user "root"
#   code "su -c 'rvm --default #{ruby_version}' - root"
# end

port_start = node["spontaneous"]["upstream_port"]

template "/etc/profile.d/spontaneous.sh" do
  source "profile-spontaneous.sh.erb"
  owner  "root"
  group  "root"
  mode   "644"
end

directory "/etc/nginx/ssl"

sites.each_with_index do |site, index|
  login         = site[:login]
  home          = "/home/#{login}"
  rbenv_dir     = "#{home}/.rbenv"
  upstream_port = port_start + index
  front_socket  = "/tmp/#{ login }_front.sock"
  back_socket   = "/tmp/#{ login }_back.sock"

  group node[:simultaneous][:group] do
    action :manage
    append true
    members login
  end

  file "#{home}/.bashrc" do
    owner   login
    group   login
    mode    "600"
    content "export SPOT_ENV=production\nsource /etc/profile.d/rbenv.sh"
    action  :create
  end


  directory "#{home}/.ssh" do
    action :create
    owner login
    group login
    mode "700"
    recursive true
  end


  require_recipe "user_#{login}"

  copy_authorized_keys login do
    user login
  end

  if site[:secure]
    copy_ssl_certificates site
  end


  %w(service service/enabled service/available).each do |dir|
    directory "#{home}/#{dir}" do
      owner login
      group login
      mode "755"
    end
  end

  runit_service "runsvdir-#{login}" do #, :template_name => "site" do
    template_name "site"
    options({
      :login => login,
      :home  => home
    })
  end


  gemset   = "spontaneous"


  rbenv_gem "bundler" do
    rbenv_version ruby_version
    version       node["ruby"]["bundler_version"]
    user          "root"
  end

  %w(config/env media revisions releases shared shared/log shared/tmp shared/pids shared/system).
    map { |subdir| ::File.join(home, "spontaneous", subdir) }.each do |dir|

    directory dir do
      action :create
      mode  "755"
      recursive true
    end
  end

  file "#{home}/spontaneous/shared/log/publish.log" do
    owner  login
    group  login
    backup false
    mode   "600"
    action :create_if_missing
  end

  # because the directory command only sets the owner on the leaf node rather than
  # the whole path:
  execute "chown -R #{login}:#{login} #{home}/spontaneous"

  template "#{ node[:nginx][:dir] }/sites-available/#{login}_front.conf" do
    source "nginx-front.conf.erb"
    mode "644"
    owner login
    group login
    variables({
      :site => site,
      :home => home,
      :front_socket => front_socket
    })
    notifies :restart, "service[nginx]"
  end


  template "#{ node[:nginx][:dir] }/sites-available/#{login}_back.conf" do
    source "nginx-back.conf.erb"
    mode "644"
    owner login
    group login
    variables({
      :site => site,
      :home => home,
      :back_socket => back_socket,
      :ssl_certificate => File.join(node[:nginx][:ssl_certificate_root], "#{site[:server_name][:back]}.crt"),
      :ssl_certificate_key => File.join(node[:nginx][:ssl_certificate_root], "#{site[:server_name][:back]}.key"),
      :secure => site[:secure]
    })
    notifies :restart, "service[nginx]"
  end

  link "#{ node[:nginx][:dir] }/sites-enabled/#{login}_front.conf" do
    to "#{ node[:nginx][:dir] }/sites-available/#{login}_front.conf"
    owner login
    group login
    action :create
    notifies :restart, "service[nginx]"
  end

  link "#{ node[:nginx][:dir] }/sites-enabled/#{login}_back.conf" do
    to "#{ node[:nginx][:dir] }/sites-available/#{login}_back.conf"
    owner login
    group login
    action :create
    notifies :restart, "service[nginx]"
  end

  service "nginx"

  generate_ssh_keys login do
    user_account login
  end

  # Checkout app
  git "#{home}/spontaneous/shared/cached-copy" do
    repository  site[:repository]
    revision    "HEAD"
    user        login
    group       login
    action      :sync
  end


  ruby_block "load_database_settings" do
    block do
      require 'yaml'

      database_settings = "#{home}/spontaneous/shared/cached-copy/config/database.yml"
      if ::File.exist?(database_settings)
        database_config = YAML.load_file(database_settings)[:production]

        run_context = Chef::RunContext.new(node, {})

        database = Chef::Resource::MysqlDatabase.new(database_config[:database], run_context)
        database.connection({
          :username => "root",
          :password => node[:mysql][:server_root_password]
        })
        database.run_action(:create)

        database_user = Chef::Resource::MysqlDatabaseUser.new(database_config[:user], run_context)

        database_user.username database_config[:user]
        database_user.password database_config[:password]
        database_user.database_name database_config[:database]
        database_user.connection({
          :username => "root",
          :password => node[:mysql][:server_root_password]
        })
        database_user.run_action(:grant)
      end
    end
    action :create
  end

  # Create env settings
  environment = {
    "SIMULTANEOUS_SOCKET" => node[:simultaneous][:socket],
    "SPONTANEOUS_BINARY" => "#{home}/spontaneous/current/bin/spot",
    "SPONTANEOUS_SERVER" => back_socket,
    "POST_PUBLISH_COMMAND" => "/usr/bin/sv hup #{home}/service/enabled/front",
    "RUBY_BIN" => "#{login}_ruby"
  }.merge(site[:environment])

  env_dir = "#{home}/spontaneous/config/env"
  environment.each do |key, value|
    file "#{env_dir}/#{key}" do
      content value
      owner   login
      group   login
      mode    "600"
      backup  false
    end
  end

  # Create Thin & Unicorn config files (in ~/spontaneous/config)
  template "#{home}/spontaneous/config/unicorn.conf.rb" do
    source "unicorn.conf.rb.erb"
    owner  login
    group  login
    mode   "644"
    variables({
      :site => site,
      :login => login,
      :home => home,
      :front_socket => front_socket
    })
  end

  template "#{home}/spontaneous/config/thin.yml" do
    source "thin.yml.erb"
    owner  login
    group  login
    mode   "644"
    variables({
      :site => site,
      :login => login,
      :home => home,
      :back_socket => back_socket
    })
  end

  %w(front back).each do |server|
    runit_service server do #, :template_name => "site" do
      template_name    server
      directory        "#{home}/service/available"
      active_directory "#{home}/service/enabled"
      owner            login
      group            login
      options({
        :site => site,
        :login => login,
        :home  => home
      })
    end
  end

  # the symlinks in service end up being owned by root
  execute "chown -R #{login}:#{login} #{home}/service"

  # TODO: Move back server to SSL with (self-signed) certificates
  # TODO: Need monitoring
end
