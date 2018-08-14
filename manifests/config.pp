class tadanat::config (
  $secrets        = '/etc/rsyncd.scr',
  $rsyncdscr      = lookup('rsyncdscr', {
    'default_value' => 'puppet:///modules/dmo_hiera/rsyncd.scr'}),
  $rsyncdconf     = lookup('rsyncdconf', {
    'default_value' => 'puppet:///modules/dmo_hiera/rsyncd.conf'}),
  $rsyncpwd       = lookup('rsyncpwd', {
    'default_value' => 'puppet:///modules/dmo_hiera/rsync.pwd'}),
  $logging_conf   = lookup('tada_logging_conf', {
    'default_value' => 'puppet:///modules/dmo_hiera/tada-logging.yaml'}),
  $dqcli_log_conf = lookup('dqcli_logging_conf', {
    'default_value' => 'puppet:///modules/dmo_hiera/dqcli-logging.yaml'}),
  $watch_log_conf = lookup('watch_logging_conf'),
  $dq_conf     = lookup('dq_conf', {
    'default_value' => 'puppet:///modules/dmo_hiera/dq-config.json'}),
  $tada_conf      = lookup('tada_conf'),
  $smoke_conf     = lookup('smoke_conf'),
  $host_type      = lookup('tada_host_type', {'default_value' => 'MOUNTAIN'}),
  $dq_loglevel    = lookup('dq_loglevel'),
  $qname          = lookup('qname', {'default_value' => 'transfer'}),

  $udp_recv_channel   = lookup('udp_recv_channel'),
  $udp_send_channel   = lookup('udp_send_channel'),
  $tcp_accept_channel = lookup('tcp_accept_channel'),
  $inotify_instances  = lookup('inotify_instances', {'default_value' => '512'}),
  $inotify_watches    = lookup('inotify_watches',{'default_value' => '1048576'}),

  # Use these to install a yaml file that TADA can use to get underlying values
  $dq_host             = lookup('dq_host'),
  $dq_port             = lookup('dq_port'),
  $natica_host         = lookup('natica_host'),
  $natica_port         = lookup('natica_port'),
  $natica_timeout      = lookup('natica_timeout'),
  $test_mtn_host       = lookup('test_mtn_host'),
  $valley_host         = lookup('valley_host'),
  $dataqversion        = lookup('dataqversion'),
  $tadaversion         = lookup('tadanatversion'),
  $hdrfunclibversion   = lookup('hdrfunclibversion'),
  $marsversion         = lookup('marsnatversion'),
  ) {
  notice("Loading tadanat::config; rsyncpwd=${rsyncpwd}")
  
  file { [ '/var/run/tada', '/var/log/tada', '/etc/tada', '/var/tada']:
    ensure => 'directory',
    owner  => 'tada',
    group  => 'tada',
    mode   => '0774',
  }
  file { '/var/tada/data':
    ensure => 'directory',
    owner  => 'tada',
    group  => 'tada',
    mode   => '0774',
  }
  file { ['/var/tada/data/cache',
          '/var/tada/data/anticache',
          '/var/tada/data/dropbox',
          '/var/tada/data/nowatch',
          '/var/tada/data/statusbox']:
    ensure => 'directory',
    owner  => 'tada',
    group  => 'tada',
    mode   => '0744',
  }
  file { '/var/tada/cache' :
    ensure  => 'link',
    replace => false,
    target  => '/var/tada/data/cache',
  }
  file { '/var/tada/anticache' :
    ensure  => 'link',
    replace => false,
    target  => '/var/tada/data/anticache',
  }
  file { '/var/tada/dropbox' :
    ensure  => 'link',
    replace => false,
    target  => '/var/tada/data/dropbox',
    owner  => 'tada',
    group  => 'tada',
    mode   => '0744',
  }
  file { '/var/tada/nowatch' :
    ensure  => 'link',
    replace => false,
    target  => '/var/tada/data/nowatch',
  }
  file { '/var/tada/statusbox' :
    ensure  => 'link',
    replace => false,
    target  => '/var/tada/data/statusbox',
  }
  file { '/var/tada/statusbox/tada-ug.pdf':
    ensure    => 'present',
    replace => true,
    subscribe => [Vcsrepo['/opt/tada'], ],
    owner     => 'tada',
    group     => 'tada',
    mode      => '0400',
    source    => '/opt/tada/docs/tada-ug.pdf',
  }
  file { '/var/tada/personalities':
    ensure  => 'link',
    replace => true,
    target  => '/opt/tada-cli/personalities',
  }
  file { '/usr/local':
    ensure => 'directory',
  }
  file { '/usr/local/bin':
    ensure => 'directory',
  }
  file { '/home/tada/.tada':
    ensure  => 'directory',
    owner   => 'tada',
    group   => 'tada',
    mode    => '0744',
  }
  file { '/home/tada/.tada/rsync.pwd':
    ensure  => 'present',
    replace => true,
    owner   => 'tada',
    group   => 'tada',
    mode    => '0400',
    source  => "${rsyncpwd}",
  }
  file { '/home/tester/.tada':
    ensure  => 'directory',
    owner   => 'tester',
    group   => 'tada',
    mode    => '0744',
  }
  file { '/home/tester/.tada/rsync.pwd':
    ensure  => 'present',
    replace => false,
    owner   => 'tester',
    mode    => '0400',
    source  => "${rsyncpwd}",
  }
  file { '/home/tester/activate':
    ensure  => 'present',
    replace => false,
    owner   => 'tester',
    mode    => '0555',
    content => "source /opt/tada/venv/bin/activate",
  }
  file { ['/var/log/tada/pop.log', '/var/log/tada/pop-detail.log']:
    ensure  => 'present',
    replace => false,
    owner   => 'tada',
    group   => 'tada',
    mode    => '0774',
  }
  file { ['/var/log/tada/dqcli.log', '/var/log/tada/dqcli-detail.log']:
    ensure  => 'present',
    replace => false,
    owner   => 'tada',
    group   => 'tada',
    mode    => '0777',
  }
  file {  '/etc/tada/smoke-config.sh':
    ensure  => 'present',
    replace => false,
    source  => "${smoke_conf}",
    group   => 'root',
    mode    => '0774',
  }
  file {  '/etc/tada/tada.conf':
    ensure  => 'present',
    replace => false,
    source  => "${tada_conf}",
    group   => 'root',
    mode    => '0774',
  }
  file {  '/etc/tada/from-hiera.yaml':
    ensure  => 'present',
    replace => true,
    content => "---
dq_host: ${dq_host}
dq_port: ${dq_port}
dq_loglevel: ${dq_loglevel}
natica_host: ${natica_host}
natica_port: ${natica_port}
natica_timeout: ${natica_timeout}
test_mtn_host: ${test_mtn_host}
valley_host: ${valley_host}
tadaversion: ${tadaversion}
dataqversion: ${dataqversion}
marsversion: ${marsversion}
",
    group   => 'root',
    mode    => '0774',
  }
  file {  '/etc/tada/dq-config.json':
    ensure  => 'present',
    replace => false,
    source  => "${dq_conf}",
    group   => 'root',
    mode    => '0774',
  }

  file { '/etc/tada/pop.yaml':
    ensure  => 'present',
    replace => false,
    source  => "${logging_conf}",
    mode    => '0774',
  }
  file { '/etc/tada/dataq_cli_logconf.yaml':
    ensure  => 'present',
    replace => false,
    source  => "${dqcli_log_conf}",
    mode    => '0774',
  }
  file { '/etc/tada/watch.yaml':
    ensure  => 'present',
    replace => false,
    source  => "${watch_log_conf}",
    mode    => '0774',
  }
  file { '/var/log/tada/submit.manifest':
    ensure  => 'file',
    replace => false,
    owner   => 'tada',
    mode    => '0766',
  }
  file { '/etc/tada/requirements.txt':
    ensure => 'present',
    replace => false,
    source => 'puppet:///modules/tadanat/requirements.txt',
  }
  file { '/etc/tada/audit-schema.sql':
    ensure => 'present',
    replace => false,
    source => 'puppet:///modules/tadanat/audit-schema.sql',
  }
  file { '/etc/init.d/dqd':
    ensure => 'present',
    replace => true,
    source => 'puppet:///modules/tadanat/dqd',
    owner  => 'tada',
    mode   => '0777',
  }
  file {  '/etc/tada/dqd.conf':
    ensure  => 'present',
    replace => true,
    content => "
qname=${qname}
dqlevel=${dq_loglevel}
",
  }
  file {  '/etc/tada/watchpushd.conf':
    ensure  => 'present',
    replace => false,
    source  => 'puppet:///modules/tadanat/watchpushd.conf',
  }
  file { '/etc/tada/EXAMPLE_prefix_table.csv':
    ensure => 'present',
    replace => false,
    source => 'puppet:///modules/tadanat/prefix_table.csv',
    owner  => 'tada',
    mode   => '0777',
  }
  file { '/etc/init.d/watchpushd':
    ensure  => 'present',
    replace => true,
    source  => 'puppet:///modules/tadanat/watchpushd',
    owner   => 'tada',
    mode    => '0777',
  }
#!  # Not sure if firewall mods needed for dqsvcpop???
#!  firewall { '000 allow dqsvcpop':
#!    chain   => 'INPUT',
#!    state   => ['NEW'],
#!    dport   => '6379',
#!    proto   => 'tcp',
#!    action  => 'accept',
#!  }

  file_line { 'config_inotify_instances':
    ensure => present,
    path   => '/etc/sysctl.conf',
    match  => '^fs.inotify.max_user_instances\ \=',
    line   => "fs.inotify.max_user_instances = $inotify_instances",
  }
  file_line { 'config_inotify_watches':
    ensure => present,
    path   => '/etc/sysctl.conf',
    match  => '^fs.inotify.max_user_watches\ \=',
    line   => "fs.inotify.max_user_watches = $inotify_watches",
  }


  ##############################################################################
  ### rsync
  file { '/etc/tada/rsync.pwd':
    ensure => 'present',
    replace => false,
    source => "${rsyncpwd}",
    mode   => '0400',
    owner  => 'tada',
  }
  file {  $secrets:
    ensure  => 'present',
    replace => false,
    source  => "${rsyncdscr}",
    owner   => 'root',
    mode    => '0400',
  }
 file {  '/etc/rsyncd.conf':
    ensure  => 'present',
    replace => true,
    source  => "${rsyncdconf}",
    owner   => 'root',
    mode    => '0400',
  }
  #!class { 'firewall': } ->
  #!firewall { '999 disable firewall':
  #!  ensure => 'stopped',
  #!}
  #!class { selinux:
  #!  mode => 'permissive',
  #!}
#!  class { 'firewall': } ->
#!  firewall { '000 allow rsync':
#!    chain   => 'INPUT',
#!    state   => ['NEW'],
#!    dport   => '873',
#!    proto   => 'tcp',
#!    action  => 'accept',
  #!  }

  file { '/etc/logrotate.d/tada':
    ensure  => 'present',
    replace => true,
    source  => 'puppet:///modules/tadanat/tada.logrotate',
  }

  file { '/home/tester/.ssh/':
    ensure => 'directory',
    owner  => 'tester',
    mode   => '0700',
  } 
  file { '/home/tester/.ssh/authorized_keys':
    owner  => 'tester',
    mode   => '0600',
  }
  }

