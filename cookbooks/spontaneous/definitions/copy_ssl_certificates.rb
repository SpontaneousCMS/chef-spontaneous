define :copy_ssl_certificates, :site => nil do
  site = params[:site] || params[:name]
  name = site[:name]
  fqdn = site[:server_name][:back]

  cookbook_file File.join(node[:nginx][:ssl_key_root], "#{fqdn}.key") do
    mode   "640"
    owner  "root"
    group  "ssl-cert"
    source "#{fqdn}.key"
    cookbook "certificates_#{name}"
  end

  tmp_cert = File.join("/tmp", "#{fqdn}.crt")
  cert_file = File.join(node[:nginx][:ssl_certificate_root], "#{fqdn}.crt")

  cookbook_file tmp_cert do
    source "#{fqdn}.crt"
    cookbook "certificates_#{name}"
  end

  cookbook_file "/tmp/startssl-ca.pem" do
    source    "ca.pem"
    cookbook  "start-ssl"
  end

  cookbook_file "/tmp/startssl-sub.pem" do
    source    "sub.class1.server.ca.pem"
    cookbook  "start-ssl"
  end


  template cert_file do
    mode "644"
    source "cert.erb"
    variables({
      :site_cert => tmp_cert,
      :ca_cert   => "/tmp/startssl-ca.pem" ,
      :sub_cert  => "/tmp/startssl-sub.pem" ,
    })
  end
end
