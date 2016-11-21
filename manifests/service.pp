# Service resources, and anything else related to the running state of
# the software.
# https://docs.puppetlabs.com/guides/module_guides/bgtm.html

class tada::service  (
  $cache    = '/var/tada/cache',  
  ) {  

  ## source /opt/tada/venv/bin/activate  

  # For exec, use something like:
    #   unless  => '/usr/bin/pgrep -f "manage.py runserver"',
    # to prevent running duplicate.  Puppet is supposed to check process table so
    # duplicate should never happen UNLESS done manually.
  service { 'dqd':
    ensure   => 'running',
    subscribe => [File ['/etc/tada/dqd.conf',
                        '/etc/init.d/dqd',
                        '/etc/tada/hiera.yaml',
                        '/etc/tada/tada.conf'
                        ],
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
    subscribe => [File ['/etc/tada/watchpushd.conf',
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
  
  }
