
define :rbenv_user, :user => nil, :home => nil do
  puts "params::"
  p params
  user    = params[:name]
  home    = params[:home] || File.join(node['rbenv']['user_home_root'], user)
  bashrc  = "#{home}/.bashrc"

  puts "user #{user}"
  puts "home #{home}"
  puts "home #{bashrc}"

  node[:rbenv_temp] = {
    :user => user,
    :home => home,
    :bashrc => bashrc
  }
  template "/etc/profile.d/rbenv.sh" do
    source  "rbenv.sh.erb"
    owner   "root"
    mode    "0755"
    cookbook "rbenv"
  end

  directory "#{home}/.rbenv" do
    mode  "755"
    owner user
    group user
  end

  directory "#{home}/.rbenv/versions" do
    mode  "755"
    owner user
    group user
  end

  # bash "Update bashrc with rbenv settings" do
  #   user user
  #   code <<-CODE
  #     echo '' >> #{bashrc}
  #     echo '# add rbenv settings to non-login shells' >> #{bashrc}
  #     echo 'source /etc/profile.d/rbenv.sh'           >> #{bashrc}
  #   CODE
  #   # not_if { p node[:rbenv_temp]; File.exist?(bashrc) and (File.read(bashrc) =~ /rbenv\\\\.sh/) }
  # end
end
