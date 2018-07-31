# Service resources, and anything else related to the running state of
# the software.
# https://docs.puppetlabs.com/guides/module_guides/bgtm.html

class tadanat::service  (
   $cache    = '/var/tada/cache',
  ) {  

  ## source /opt/tada/venv/bin/activate  

  # For exec, use something like:
    #   unless  => '/usr/bin/pgrep -f "manage.py runserver"',
    # to prevent running duplicate.  Puppet is supposed to check process table so
    # duplicate should never happen UNLESS done manually.
  service { 'dqd':
    ensure   => 'running',
    subscribe => [File['/etc/tada/dqd.conf',
                       '/etc/init.d/dqd',
                       '/etc/tada/from-hiera.yaml',
                       '/etc/tada/tada.conf',
                       ],
                  Vcsrepo['/opt/tada/tada/hdrfunclib'],
                  Class['redis'],
                  Python::Requirements[ '/opt/tada/requirements.txt'],
                  #! Package['python-dataq', 'python-tada'],
                  Exec['install tada'],
                  Exec['install dataq'],
                  ],
    enable   => true,
    provider => 'redhat',
    path     => '/etc/init.d',
  }
  # WATCH only needed for MOUNTAIN (so far)
  service { 'watchpushd':
    ensure    => 'running',
    subscribe => [File['/etc/tada/watchpushd.conf',
                       '/etc/init.d/watchpushd'
                       ],
                  Python::Requirements[ '/opt/tada/requirements.txt'],
                  #! Package['python-dataq', 'python-tada'],
                  Exec['install tada'],
                  Exec['install dataq'],
                  ],
    enable    => true,
    provider  => 'redhat',
    path      => '/etc/init.d',
  }
  
  file { '/etc/patch.sh':
    replace => true,
    source  => lookup('patch_tadanat',{
      'default_value' => 'puppet:///modules/tadanat/patch.sh'}),
    mode    => 'a=rx',
    } ->
  exec { 'patch tada':
    command => "/etc/patch.sh > /etc/patch.log",
    creates => "/etc/patch.log",
    }
  service { 'xinetd':
    ensure  => 'running',
    enable  => true,
    require => Package['xinetd'],
    }
  #!exec { 'rsyncd':
  #!  command   => '/sbin/chkconfig rsync on',
  #!  require   => [Service['xinetd'],],
  #!  subscribe => File['/etc/rsyncd.conf'],
  #!  onlyif    => '/sbin/chkconfig --list --type xinetd rsync | grep off',
  #!}
  exec { 'bootrsyncd':
    command   => '/bin/systemctl enable rsyncd',
    creates   => '/etc/systemd/system/multi-user.target.wants/rsyncd.service',
  }
  exec { 'rsyncd':
    command   => '/bin/systemctl start rsyncd',
    subscribe => File['/etc/rsyncd.conf'],
    unless    => '/bin/systemctl status rsyncd.service | grep "Active: active"',
  }
  }
