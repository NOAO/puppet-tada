class tadanat (
  $rsyncpwd       = hiera('rsyncpwd'),
  ) {
  include tadanat::install
  include tadanat::config
  include tadanat::service
}
