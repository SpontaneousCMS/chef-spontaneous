define :copy_authorized_keys, :user => nil, :home => nil do
  username = params[:user]

  raise ":user_account should be provided." if username.nil?

  home = params[:home] || "/home/#{username}"
  ssh_dir = File.join(home, '.ssh')
  key_dir = File.join(ssh_dir, '.authorized_keys')


  remote_directory key_dir do
    source "authorized_keys"
    files_owner  username
    files_group  username
    files_mode   "600"
    owner        username
    group        username
    files_backup false
    cookbook     "authorized_keys"
  end

  file File.join(ssh_dir, 'authorized_keys') do
    # owner  username
    # group  username
    # mode   "600"
    action :delete
  end

  bash "Concatenate authorized keys" do
    code "cat #{key_dir}/* > #{ssh_dir}/authorized_keys"
    user username
  end
end

