name        "spontaneous"
description "Basic server setup for Spontaneous mothership"
run_list    \
  "recipe[apt]",
  "recipe[bytemark-init]",
  "recipe[git]",
  "recipe[vim]",
  "recipe[runit]",
  "recipe[nginx::source]",
  "recipe[openssl]",
  "recipe[imagemagick]",
  "recipe[mysql::server]",
  "recipe[ruby_build]",
  "recipe[rbenv]",
  "recipe[logins]",
  "recipe[ruby]",
  "recipe[simultaneous]",
  "recipe[spontaneous]"

default_attributes(

  "spontaneous" => {
    # base port for upstream thin servers
    "upstream_port" => 3000
  },
  "ruby_build" => {
    "upgrade" => "sync"
  },
  "nginx" => {
    "version" => "1.0.12",
    "disable_access_log" => true,
    "ssl_certificate_root" => "/etc/nginx/ssl",
    "ssl_key_root" => "/etc/nginx/ssl"
  },
  "ruby" => {
    "version"         => "1.9.3-p125",
    "bundler_version" => "1.1.rc.7"
  },
  "rvm" => {
    "global_gems" => [
      # { "name" => "rake", "version" => "~> 9.2" },
      # { "name" => "bundler", "version" => "~> 1.1.rc.7" }
    ]
  }
)
