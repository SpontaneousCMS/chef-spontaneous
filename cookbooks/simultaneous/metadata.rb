maintainer       "Garry Hill"
maintainer_email "garry@magnetised.net"
license          "MIT"
description      "Installs/Configures a Simultaneous job server"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.1"


depends          "rvm"
depends          "runit"

attribute "simultaneous/version",
  :display_name => "Simultaneous Version",
  :description => "Version of Simultaneous Gem to use",
  :default => "0.2.0"

attribute "simultaneous/ruby_version",
  :display_name => "Ruby Version",
  :description => "Version of Ruby to run the server with (RVM compatible)",
  :default => "1.9.3"

attribute "simultaneous/gemset",
  :display_name => "Gemset Name",
  :description => "Name of the Gemset to use for the server",
  :default => "simultaneous"

attribute "simultaneous/wrapper",
  :display_name => "Wrapper Name",
  :description => "Prefix of the RVM wrapper",
  :default => "global"

attribute "simultaneous/service",
  :display_name => "Service Name",
  :description => "Name of runit service",
  :default => "simultaneous"

attribute "simultaneous/socket",
  :display_name => "Socket File",
  :description => "Path to UNIX socket file",
  :default => "/var/run/simultaneous.sock"

attribute "simultaneous/group",
  :display_name => "Group",
  :description => "Group that all users must belong to",
  :default => "spontaneous"
