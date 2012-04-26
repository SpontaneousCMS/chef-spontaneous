
# create the site users
sites = node[:sites]


sites.each do |site|
  login         = site[:login]
  home          = "/home/#{login}"

  user login do
    comment  site[:server_name][:front].first
    home     home
    password site[:password]
    shell    "/bin/bash"
  end

  directory home do
    owner login
    group login
    mode "755"
    recursive true
  end
end
