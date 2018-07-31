

class tadanat::install (
  $fpacktgz    = lookup('fpacktgz', {
    'default_value' => 'puppet:///modules/tadanat/fpack-bin-centos-6.6.tgz'}),
  $tadanatversion = lookup('tadanatversion', {
    'default_value' => 'master'}),
  $dataqversion = lookup('dataqversion', {
    'default_value' => 'master'}),
  $hdrfunclibversion = lookup('hdrfunclibversion', {
    'default_value' => 'master'}),
  $marsnat_pubkey = lookup('mars_pubkey', {
    'default_value' => 'puppet:///modules/dmo_hiera/spdev1.id_dsa.pub'}),
  ) {
  notice("Loading tadanat::install; tadanatversion=${tadanatversion}, dataqversion=${dataqversion}")
  notify{"tadanat::install.pp":}
  #include git



  # Top-level dependency to support full tada re-provision
  # To force re-provision: "rm /opt/tada-release" on BOTH mtn and valley
  #! $stamp=strftime("%Y-%m-%d %H:%M:%S")
  $stamp = generate('/bin/date', '+%Y-%m-%d %H:%M:%S')
  exec { 'provision tada':
    path    => '/usr/bin:/usr/sbin:/bin',
    command => "rm -rf /etc/tada/ /var/log/tada /var/run/tada /home/tada/.tada  /home/tester/.tada",
    onlyif => 'test \! -f /opt/tada-release',
    } ->
    file { '/opt/tada-release':
      ensure  => 'present',
      replace => false,
      content => "$stamp
      ",
      #'/var/tada', # do NOT change history on reprovision!
      notify  => [File['/etc/tada', '/var/log/tada', '/var/run/tada',
                       '/home/tada/.tada', '/home/tester/.tada'],
                  Vcsrepo['/opt/tada', '/opt/tada-cli','/opt/data-queue' ]
                  ]
    }
  
    # these are also given by: puppet-sdm
    ensure_resource('package', ['git', 'libyaml'], {'ensure' => 'present'})
    #!ensure_resource('package', ['libyaml'], {'ensure' => 'present'})
    #! include augeas

  package { ['xinetd', 'postgresql-devel'] : }
  yumrepo { 'ius':
    descr      => 'ius - stable',
    #!baseurl    => 'http://dl.iuscommunity.org/pub/ius/stable/CentOS/6/x86_64/',
    baseurl    => 'http://dl.iuscommunity.org/pub/ius/stable/CentOS/7/x86_64/',
    enabled    => 1,
    gpgcheck   => 0,
    priority   => 1,
    mirrorlist => absent,
  }
  -> Package<| provider == 'yum' |>


  # These install tada,dataq from source in /opt/tada,data-queue
  exec { 'install dataq':
    cwd     => '/opt/data-queue',
    command => "/bin/bash -c  /opt/data-queue/scripts/dataq-valley-install.sh",
    refreshonly  => true,
    logoutput    => true,
    notify  => [Service['watchpushd'], Service['dqd'], ],
    subscribe => [
      Vcsrepo['/opt/data-queue'], 
      File['/opt/tada/venv', '/etc/tada/from-hiera.yaml'],
      Python::Requirements['/opt/tada/requirements.txt'],
    ],
  } ->
  exec { 'install tada':
    cwd          => '/opt/tada',
    command      => "/bin/bash -c /opt/tada/scripts/tada-valley-install.sh",
    refreshonly  => true,
    logoutput    => true,
    notify       => [Service['watchpushd'], Service['dqd'], ],
    subscribe    => [
                     Vcsrepo['/opt/tada'], 
                     File['/opt/tada/venv'], 
                     File['/etc/tada/from-hiera.yaml'],
                     Python::Requirements['/opt/tada/requirements.txt'],
                     ],
  }

  package{ ['epel-release', 'jemalloc'] : } ->
  class { '::redis':
      protected_mode => 'no',
      #! bind => undef,  # Will cause DEFAULT (127.0.0.1) value to be used
      #! bind => '172.16.1.21', # @@@ mtnnat
      bind => '0.0.0.0', # @@@ Listen to ALL interfaces
      #! bind => '127.0.0.1 172.16.1.21', # listen to Local and mtnnat.vagrant
    } ->
  package{ ['python36u-pip', 'python34-pylint'] : } ->
    # Will try to install wrong (python3-pip) version of pip under non-SCL.
    # We WANT:
    #   sudo yum -y install python36u-pip
  class { 'python' :
    version    => 'python36u',
    ensure     => 'latest',
    pip        => 'absent', # 'latest' will try to install "python3-pip"
    dev        => 'latest',
    gunicorn   => 'absent',
    } ->
#!  file { '/usr/bin/python3':
#!    ensure => 'link',
#!    #target => '/usr/bin/python3.5',
#!    target => '/usr/bin/python3.6',
#!    } ->
  python::pyvenv  { '/opt/tada/venv':
    version  => '3.6',
    owner    => 'tada',
    group    => 'tada',
    require  => [ User['tada'], ],
  } ->
  python::requirements  { '/opt/tada/requirements.txt':
    virtualenv => '/opt/tada/venv',
    pip_provider => 'pip3',
    owner      => 'tada',
    group      => 'tada',
    forceupdate  => true,
    require    => [ User['tada'], ],
  }
  #!->
  #!python::pip { 'pylint' :
  #! pkgname    => 'pylint',
  #! ensure     => 'latest',
  #! virtualenv => '/opt/tada/venv',   
  #! owner      => 'tada',
  #! }
  
 

  # Some old/vulnerable NSS is used for SSL within cURL library when you
  # go to some url, so it's rejected. So within this machine you have
  # chance to fail to run cURL related commands such as pycurl.
  #
  # It seems the NSS is bundle with CentOS 7.0 VM, so you can update NSS
  # libraries as following:
  #    yum update curl nss
  #           OR
  #    yum update curl nss nss-util nspr

  # CONFLICTS with puppet-sdm.  Instead:
  #   sudo yum -y update nss curl libcurl
  # Following will fail because NAME is used for uniqueness
  #!package { 'update curl':
  #!    name   => ['nss', 'curl', 'libcurl'],
  #!    ensure => 'latest',
  #!  } ->
  vcsrepo { '/opt/tada-cli' :
    ensure   => latest,
    #!ensure   => bare,
    provider => git,
    #!source   => 'git@github.com:NOAO/tada-cli.git',
    source   => 'https://github.com/NOAO/tada-cli.git',
    revision => 'master',
  }
  group { 'tada':
    ensure => 'present',
  } -> 
  user { 'tada' :
    ensure     => 'present',
    comment    => 'For running TADA related services and actions',
    managehome => true,
    password   => '$1$Pk1b6yel$tPE2h9vxYE248CoGKfhR41',  # tada"Password"
    system     => true,
    }

  user { 'tester' :
    ensure     => 'present',
    comment    => 'For running TADA related tests',
    managehome => true,
    password   => '$1$Pk1b6yel$tPE2h9vxYE248CoGKfhR41',  # tada"Password"
    groups     => ['tada'],
    system     => false,
  }
  vcsrepo { '/opt/tada' :
    ensure   => latest,
    #!ensure   => bare,
    provider => git,
    #!source   => 'git@github.com:NOAO/tadanat',
    source   => 'https://github.com/NOAO/tadanat.git',
    revision => "${tadanatversion}",
    owner    => 'tada', # 'tester', # 'tada',
    group    => 'tada',
    require  => User['tada'],
    notify   => Exec['install tada'],
    } ->
  vcsrepo { '/opt/tada/tada/hdrfunclib' :
    ensure   => latest,
    #!ensure   => bare,
    provider => git,
    source   => 'https://github.com/NOAO/hdrfunclib.git',
    revision => "${hdrfunclibversion}", 
    owner    => 'tada', 
    group    => 'tada',
    require  => User['tada'],
    notify   => Exec['install tada'],
    } ->
  file { '/opt/tada/tests/smoke':
      ensure  => directory,
      mode    => '0774',
      recurse => true,
      }
  vcsrepo { '/opt/data-queue' :
    ensure   => latest,
    #!ensure   => bare,
    provider => git,
    #!source   => 'git@github.com:NOAO/data-queue.git',
    source   => 'https://github.com/NOAO/data-queue.git',
    revision => "${dataqversion}",
    owner    => 'tada', # 'tester', #'tada',
    group    => 'tada',
    require  => User['tada'],
    notify   => Exec['install dataq'],
  }

  file { '/usr/local/share/applications/fpack.tgz':
    ensure => 'present',
    replace => false,
    source => "$fpacktgz",
    notify => Exec['unpack fpack'],
  } 
  exec { 'unpack fpack':
    command     => '/bin/tar -xf /usr/local/share/applications/fpack.tgz',
    cwd         => '/usr/local/bin',
    refreshonly => true,
  } 
  file { '/usr/local/bin/fitsverify' :
    ensure  => present,
    replace => false,
    source  => 'puppet:///modules/tadanat/fitsverify',
  } 
  file { '/usr/local/bin/fitscopy' :
    ensure  => present,
    replace => false,
    source  => 'puppet:///modules/tadanat/fitscopy',
  }
  # just so LOGROTATE doesn't complain if it runs before we rsync
  file { '/var/log/rsyncd.log' :
    ensure  => present,
    replace => false,
  }

  #!concat { '/home/vagrant/.ssh/authorized_keys':
  #!  ensure_newline => true,
  #!  owner          => 'vagrant',
  #!  group          => 'vagrant',
  #!  mode           => '0600',
  #!  replace        => false,
  #!} 
  #!concat::fragment { 'authorize marsnat':
  #!  target         => '/home/vagrant/.ssh/authorized_keys',
  #!  source         => "${marsnat_pubkey}",
  #!}

}


