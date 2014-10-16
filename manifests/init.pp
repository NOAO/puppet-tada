# after: vagrant ssh
# sudo puppet apply --modulepath=/vagrant/modules /vagrant/manifests/init.pp --noop --graph
# sudo cp -r /var/lib/puppet/state/graphs/ /vagrant/

include augeas

# epel is not needed by the puppet redis module but it's nice to have it
# already configured in the box
include epel

package { 'emacs' : } 

class { 'redis':
  version        => '2.8.13',
  redis_password => 'test',
}

$dbuser = 'irods' # must match IRODS_SERVICE_ACCOUNT_NAME per manual.rst!
$dbpass = 'irods-sdm'

################### 
### Firewall setup
# Clear any existing rules and make sure that only rules defined in
# Puppet exist on the machine.
resources { "firewall":
  purge => true
}
Firewall {
  before  => Class['irods_fw::post'],
  require => Class['irods_fw::pre'],
}
class { ['irods_fw::pre', 'irods_fw::post']: }
class { 'firewall': }
class irods_fw::pre {
  Firewall {
    require => undef,
  }
 # IRODS
 firewall { '100 allow irods':
    chain   => 'INPUT',
    state   => ['NEW'],
    dport   => '1247',
    proto   => 'tcp',
    action  => 'accept',
    }->
 firewall { '101 allow irods':
    chain   => 'INPUT',
    state   => ['NEW'],
    dport   => '20000-20199',
    proto   => 'tcp',
    action  => 'accept',
    }->
 firewall { '102 allow irods':
    chain   => 'INPUT',
    state   => ['NEW'],
    dport   => '20000-20199',
    proto   => 'udp',
    action  => 'accept',
    }
}
class irods_fw::post {
  Firewall {
    require => undef,
  }
  # Default firewall rules
  # (none)
}

$irods_depends = ['postgresql-odbc', 'unixODBC',  'authd', 
                  'fuse-libs',   'openssl098e',  ]
$irodsbase = "ftp://ftp.renci.org/pub/irods/releases/4.0.3"
package { $irods_depends : } ->
package { 'irods-icat':
  provider => 'rpm',
  source   => "$irodsbase/irods-icat-4.0.3-64bit-centos6.rpm",
  } -> 
package { 'irods-runtime':
  provider => 'rpm',
  source   => "$irodsbase/irods-runtime-4.0.3-64bit-centos6.rpm",
  } -> 
package { 'irods-icommands':
  provider => 'rpm',
  source   => "$irodsbase/irods-icommands-4.0.3-64bit-centos6.rpm",
  } ->
package { 'irods-database-plugin-postgres':
  provider => 'rpm',
  source   => "$irodsbase/irods-database-plugin-postgres-1.3-centos6.rpm",
  } ->
class { 'postgresql::server': } ->
postgresql::server::db { 'ICAT':
    user     => $dbuser,
    password => $dbpass,
  } 

$irods_setup_in = '/vagrant/modules/irods/setup_irods.input'
Package [ 'irods-icat' ] ->
Postgresql::Server::Db['ICAT'] ->
exec { "/var/lib/irods/packaging/setup_irods.sh < $irods_setup_in" :  
    creates => '/tmp/irods/setup_irods_configuration.flag',
    } ->
exec { '/sbin/service irods status' :
  logoutput => true,
  } -> 
exec { '/bin/su - irods -c ils' :
  logoutput => true,
  } 



yumrepo { 'ius':
  descr      => 'ius - stable',
  baseurl    => 'http://dl.iuscommunity.org/pub/ius/stable/CentOS/6/x86_64/',
  enabled    => 1,
  gpgcheck   => 0,
  priority   => 1,
  mirrorlist => absent,
} -> Package<| provider == 'yum' |>

class { 'python':
  version    => '34u',
  pip        => false,
  dev        => true,
  virtualenv => true,
} ->
package { 'python34u-pip': } ->
file { '/usr/bin/pip':
  ensure => 'link',
  target => '/usr/bin/pip3.4',
} ->
package { 'graphviz-devel': } ->
python::requirements { '/vagrant/requirements.txt': } ->
python::pip {'daflsim': 
    pkgname => 'daflsim',
    url     => 'https://github.com/pothiers/daflsim/archive/master.zip',
    }
