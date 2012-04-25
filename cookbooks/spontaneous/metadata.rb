maintainer       "Garry Hill"
maintainer_email "garry@magnetised.net"
license          "MIT"
description      "Configures one or more Spontaneous CMS installations"
version          "0.1.0"

recipe "spontaneous", "Installs one of more Spontaneous CMS instances. Attributes for each site should be configured in the node configuration."

depends "nginx"
depends "runit"

%w{ debian ubuntu }.each do |os|
  supports os
end

