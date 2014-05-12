/*
 * A simple puppet manifest.
 */

$local_user = 'roger'
$local_home = "/home/$local_user"

define local_config ($file, $search, $replace) {
  exec {"local-config-$name":
    command => "/usr/bin/awk '{if (match(\$0, \"$search\")) {print \"$replace\"} else {print \$0}}' $file | /usr/bin/sponge $file",
    require => Package['moreutils'],
    unless  => "/bin/grep -E \"$replace\" $file",
    onlyif  => "/usr/bin/stat $file",
  }
  ->
  exec {"local-append-$name":
    command => "/bin/grep -E \"$replace\" $file || /bin/echo \"$replace\" >> $file",
    unless  => "/bin/grep -E \"$replace\" $file",
    onlyif  => "/usr/bin/stat $file",
  }
}

$apt_mirror = "mirror.math.ucdavis.edu"
exec {'apt-mirror':
  command => "/bin/sed -i \"s/\\(us\\.archive\\|extras\\|security\\)\\.ubuntu\\.com\\/ubuntu/$apt_mirror\\/ubuntu/\" /etc/apt/sources.list",
  unless  => "/bin/grep $apt_mirror /etc/apt/sources.list",
  notify  => Exec['apt-update'],
}

exec {'apt-update':
  command => '/usr/bin/apt-get update',
  refreshonly => true,
}

define apt_key ($keyserver) {
  exec {"$name":
    command => "/usr/bin/apt-key adv --keyserver $keyserver --recv-keys $name",
    unless  => "/usr/bin/apt-key list | /bin/grep $name",
  }
}

define apt_line ($line) {
  file {"/etc/apt/sources.list.d/$name.list":
    ensure  => present,
    content => "$line\n",
    notify  => Exec['apt-update'],
  }
}

apt_key {'5044912E': keyserver => 'pgp.mit.edu'}

apt_line {'dropbox':
  line => 'deb http://linux.dropbox.com/ubuntu/ trusty main',
}

apt_key {'233DD144': keyserver => 'keyserver.ubuntu.com'}

apt_line {'nuvola-player':
  line => 'deb http://ppa.launchpad.net/nuvola-player-builders/stable/ubuntu trusty main',
}

apt_key {'7FAC5991': keyserver => 'keyserver.ubuntu.com'}

apt_line {'google-chrome':
  line => 'deb http://dl.google.com/linux/chrome/deb/ stable main',
}

apt_line {'google-talk':
  line => 'deb http://dl.google.com/linux/talkplugin/deb/ stable main',
}

apt_key {'02D65EFF': keyserver => 'keyserver.ubuntu.com'}

apt_line {'linrunner-tlp':
  line => 'deb http://ppa.launchpad.net/linrunner/tlp/ubuntu trusty main',
}

define local_package () {
  package {"$name":
    ensure => present,
    require => Exec['apt-update'],
  }
}

local_package{'vim-gnome':}
local_package{'git':}
local_package{'subversion':}
local_package{'meld':}
local_package{'moreutils':}
local_package{'whois':}
local_package{'fish':}
local_package{'python-gpgme':}
local_package{'g++':}
local_package{'keepassx':}
local_package{'unattended-upgrades':}
local_package{'keychain':}
local_package{'bmon':}
local_package{'gconf-editor':}
local_package{'apt-file':}
local_package{'gimp':}
local_package{'rdiff-backup':}
local_package{'google-chrome-stable':}
local_package{'google-talkplugin':}
local_package{'tlp':}
local_package{'lm-sensors':}
local_package{'libappindicator1':}
local_package{'vlc':}
local_package{'encfs':}
local_package{'network-manager-openvpn':}
local_package{'ruby1.9.1-dev':}
local_package{'imagemagick':}
local_package{'sqlite3':}
local_package{'dropbox': require => [
  Apt_line['dropbox'],
  Package['python-gpgme'],
  Package['libappindicator1'],
  ]}
local_package{'nuvolaplayer': require => Apt_line['nuvola-player']}

define gem () {
  exec {"install-$name":
    command => "/usr/bin/gem install $name",
    unless  => "/usr/bin/gem list --local | /bin/grep -E \"^$name \"",
  }
}

gem{'sass':}
gem{'tugboat':
  require => Package['ruby1.9.1-dev'],
}

user {"$local_user":
  shell   => '/usr/bin/fish',
  require => Package['fish'],
}

file {"$local_home/.config/fish/config.fish":
  ensure  => link,
  owner   => "$local_user",
  require => Package['fish'],
  target  => "$local_home/Configuration/config.fish",
}

file {"$local_home/.config/fish/completions":
  ensure  => link,
  owner   => "$local_user",
  require => Package['fish'],
  target  => "$local_home/Configuration/completions",
}

exec {'grub-update':
  command => '/usr/sbin/update-grub',
  refreshonly => true,
}

local_config {'grub-timeout':
  file    => '/etc/default/grub',
  search  => 'GRUB_TIMEOUT',
  replace => 'GRUB_TIMEOUT=2',
  notify  => Exec['grub-update'],
}

exec {'vim-config':
  command => "/usr/bin/git clone --recursive https://github.com/rogerhub/vim-config.git $local_home/.vim-config",
  unless  => "/usr/bin/stat $local_home/.vim-config",
  user    => "$local_user",
}

define local_link ($target) {
  file {"$local_home/$name":
    ensure => link,
    target => "$local_home/$target",
    owner  => "$local_user",
  }
}

local_config {'apport-disable':
  file    => '/etc/default/apport',
  search  => 'enabled=1',
  replace => 'enabled=0',
}

local_config {'lightdm-guest-disable':
  file    => '/etc/lightdm/users.conf',
  search  => 'allow-guest',
  replace => 'allow-guest=false'
}

local_config {'automatic-unattended-upgrades-lists':
  file   => '/etc/apt/apt.conf.d/20auto-upgrades',
  search => 'APT::Periodic::Update-Package-Lists',
  replace => 'APT::Periodic::Update-Package-Lists \"1\";',
}

local_config {'automatic-unattended-upgrades-upgrades':
  file   => '/etc/apt/apt.conf.d/20auto-upgrades',
  search => 'APT::Periodic::Unattended-Upgrade',
  replace => 'APT::Periodic::Unattended-Upgrade \"1\";',
}

local_link {'.vim': target       => '.vim-config/.vim'}
local_link {'.vimrc': target     => '.vim-config/.vimrc'}
local_link {'.gvimrc': target    => '.vim-config/.gvimrc'}
local_link {'.ssh': target       => 'Configuration/ssh'}
local_link {'.bcrc': target      => 'Configuration/bcrc'}
local_link {'.cgdbrc': target    => 'Configuration/cgdbrc'}
local_link {'.gitconfig': target => 'Configuration/gitconfig'}
local_link {'.tugboat': target   => 'Configuration/tugboat'}

file {"$local_home/Local":
  ensure => directory,
  owner  => "$local_user",
}

file {"$local_home/Private":
  ensure => directory,
  owner  => "$local_user",
}

exec {'terminal-scroll-unlimited':
  command => '/usr/bin/gconftool --type boolean --set /apps/gnome-terminal/profiles/Default/scrollback_unlimited true',
  user    => $local_user,
  unless  => '/usr/bin/gconftool --get /apps/gnome-terminal/profiles/Default/scrollback_unlimited | grep true',
}
