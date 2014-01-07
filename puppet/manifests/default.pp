## Begin Server manifest

stage { 'nginx_setup': }
stage { 'postsetup': }
stage { 'database': }
stage { 'vhost_tools': }
stage { 'bounce': }

Stage['main'] -> Stage['nginx_setup'] -> Stage['postsetup'] -> Stage['database'] -> Stage['vhost_tools'] -> Stage['bounce']

if $server_values == undef {
  $server_values = hiera('server', false)
}

# Ensure the time is accurate, reducing the possibilities of apt repositories
# failing for invalid certificates
include '::ntp'

Exec { path => [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/' ] }
File { owner => 0, group => 0, mode => 0644 }

group { 'puppet': ensure => present }
group { 'www-data': ensure => present }

user { $::ssh_username:
  shell  => "/bin/zsh",
  home   => "/home/${::ssh_username}",
  ensure => present
}

user { ['apache', 'nginx', 'httpd', 'www-data']:
  shell  => '/bin/bash',
  ensure => present,
  groups => 'www-data',
  require => Group['www-data']
}

file { "/home/${::ssh_username}":
    ensure => directory,
    owner  => $::ssh_username,
}

file { "/usr/share/nginx":
  ensure => directory,
  owner  => 'root',
}

# copy dot files to ssh user's home directory
exec { 'dotfiles':
  cwd     => "/home/${::ssh_username}",
  command => "cp -r /vagrant/files/dot/.[a-zA-Z0-9]* /home/${::ssh_username}/ && chown -R ${::ssh_username} /home/${::ssh_username}/.[a-zA-Z0-9]*",
  onlyif  => "test -d /vagrant/files/dot",
  require => User[$::ssh_username]
}

case $::osfamily {
  # debian, ubuntu
  'debian': {
    class { 'apt': }

    Class['::apt::update'] -> Package <|
        title != 'python-software-properties'
    and title != 'software-properties-common'
    |>

    ensure_packages( ['augeas-tools'] )
  }
  # redhat, centos
  'redhat': {
    class { 'yum': extrarepo => ['epel'] }

    Class['::yum'] -> Yum::Managed_yumrepo <| |> -> Package <| |>

    exec { 'bash_git':
      cwd     => "/home/${::ssh_username}",
      command => "curl https://raw.github.com/git/git/master/contrib/completion/git-prompt.sh > /home/${::ssh_username}/.bash_git",
      creates => "/home/${::ssh_username}/.bash_git"
    }

    file_line { 'link ~/.bash_git':
      ensure  => present,
      line    => 'if [ -f ~/.bash_git ] ; then source ~/.bash_git; fi',
      path    => "/home/${::ssh_username}/.bash_profile",
      require => [
        Exec['dotfiles'],
        Exec['bash_git'],
      ]
    }

    file_line { 'link ~/.bash_aliases':
      ensure  => present,
      line    => 'if [ -f ~/.bash_aliases ] ; then source ~/.bash_aliases; fi',
      path    => "/home/${::ssh_username}/.bash_profile",
      require => [
        File_line['link ~/.bash_git'],
      ]
    }

    ensure_packages( ['augeas'] )
  }
}

if $php_values == undef {
  $php_values = hiera('php', false)
}

case $::operatingsystem {
  'debian': {
    add_dotdeb { 'packages.dotdeb.org': release => $lsbdistcodename }

    if is_hash($php_values) {
      # Debian Squeeze 6.0 can do PHP 5.3 (default) and 5.4
      if $lsbdistcodename == 'squeeze' and $php_values['version'] == '54' {
        add_dotdeb { 'packages.dotdeb.org-php54': release => 'squeeze-php54' }
      }
      # Debian Wheezy 7.0 can do PHP 5.4 (default) and 5.5
      elsif $lsbdistcodename == 'wheezy' and $php_values['version'] == '55' {
        add_dotdeb { 'packages.dotdeb.org-php55': release => 'wheezy-php55' }
      }
    }
  }
  'ubuntu': {
    apt::key { '4F4EA0AAE5267A6C': }

    if is_hash($php_values) {
      # Ubuntu Lucid 10.04, Precise 12.04, Quantal 12.10 and Raring 13.04 can do PHP 5.3 (default <= 12.10) and 5.4 (default <= 13.04)
      if $lsbdistcodename in ['lucid', 'precise', 'quantal', 'raring'] and $php_values['version'] == '54' {
        if $lsbdistcodename == 'lucid' {
          apt::ppa { 'ppa:ondrej/php5-oldstable': require => Apt::Key['4F4EA0AAE5267A6C'], options => '' }
        } else {
          apt::ppa { 'ppa:ondrej/php5-oldstable': require => Apt::Key['4F4EA0AAE5267A6C'] }
        }
      }
      # Ubuntu Precise 12.04, Quantal 12.10 and Raring 13.04 can do PHP 5.5
      elsif $lsbdistcodename in ['precise', 'quantal', 'raring'] and $php_values['version'] == '55' {
        apt::ppa { 'ppa:ondrej/php5': require => Apt::Key['4F4EA0AAE5267A6C'] }
      }
      elsif $lsbdistcodename in ['lucid'] and $php_values['version'] == '55' {
        err('You have chosen to install PHP 5.5 on Ubuntu 10.04 Lucid. This will probably not work!')
      }
    }
  }
  'redhat', 'centos': {
    if is_hash($php_values) {
      if $php_values['version'] == '54' {
        class { 'yum::repo::remi': }
      }
      # remi_php55 requires the remi repo as well
      elsif $php_values['version'] == '55' {
        class { 'yum::repo::remi': }
        class { 'yum::repo::remi_php55': }
      }
    }
  }
}

if !empty($server_values['packages']) {
  ensure_packages( $server_values['packages'] )
}

define add_dotdeb ($release){
   apt::source { $name:
    location          => 'http://packages.dotdeb.org',
    release           => $release,
    repos             => 'all',
    required_packages => 'debian-keyring debian-archive-keyring',
    key               => '89DF5277',
    key_server        => 'keys.gnupg.net',
    include_src       => true
  }
}

## Begin Nginx manifest

if $nginx_values == undef {
   $nginx_values = hiera('nginx', false)
}

if $php_values == undef {
   $php_values = hiera('php', false)
}

if $::osfamily == 'debian' and $lsbdistcodename in ['lucid'] and is_hash($php_values) and $php_values['version'] == '53' {
  apt::key { '67E15F46': }
  apt::ppa { 'ppa:l-mierzwa/lucid-php5':
    options => '',
    require => Apt::Key['67E15F46']
  }
}

include puphpet::params

$webroot_location = $puphpet::params::nginx_webroot_location

exec { "exec mkdir -p ${webroot_location}":
  command => "mkdir -p ${webroot_location}",
  onlyif  => "test -d ${webroot_location}",
}

if ! defined(File[$webroot_location]) {
  file { $webroot_location:
    ensure  => directory,
    group   => 'www-data',
    mode    => 0775,
    require => [
      Exec["exec mkdir -p ${webroot_location}"],
      Group['www-data']
    ]
  }
}

$php5_fpm_sock = '/var/run/php5-fpm.sock'

if $php_values['version'] == undef {
  $fastcgi_pass = null
} elsif $php_values['version'] == '53' {
  $fastcgi_pass = '127.0.0.1:9000'
} else {
  $fastcgi_pass = "unix:${php5_fpm_sock}"
}

class { 'nginx': }

if count($nginx_values['vhosts']) > 0 {
  create_resources(nginx_vhost, $nginx_values['vhosts'])
}

if $::osfamily == 'redhat' and ! defined(Iptables::Allow['tcp/80']) {
  iptables::allow { 'tcp/80':
    port     => '80',
    protocol => 'tcp'
  }
}

define nginx_vhost (
  $server_name,
  $server_aliases = [],
  $www_root,
  $listen_port,
  $index_files,
  $envvars = [],
){
  $merged_server_name = concat([$server_name], $server_aliases)

  if is_array($index_files) and count($index_files) > 0 {
    $try_files = $index_files[count($index_files) - 1]
  } else {
    $try_files = 'index.php'
  }

  nginx::resource::vhost { $server_name:
    server_name => $merged_server_name,
    www_root    => $www_root,
    listen_port => $listen_port,
    index_files => $index_files,
    try_files   => ['$uri', '$uri/', "/${try_files}?\$args"],
  }

  $fastcgi_param = concat(
  [
    'PATH_INFO $fastcgi_path_info',
    'PATH_TRANSLATED $document_root$fastcgi_path_info',
    'SCRIPT_FILENAME $document_root$fastcgi_script_name',
  ], $envvars)

  nginx::resource::location { "${server_name}-php":
    ensure              => present,
    vhost               => $server_name,
    location            => '~ \.php$',
    proxy               => undef,
    try_files           => ['$uri', '$uri/', "/${try_files}?\$args"],
    www_root            => $www_root,
    location_cfg_append => {
      'fastcgi_split_path_info' => '^(.+\.php)(/.+)$',
      'fastcgi_param'           => $fastcgi_param,
      'fastcgi_pass'            => $fastcgi_pass,
      'fastcgi_index'           => 'index.php',
      'include'                 => 'fastcgi_params'
    },
    notify              => Class['nginx::service'],
  }
}

if $::osfamily == 'redhat' and $fastcgi_pass == "unix:${php5_fpm_sock}" {
  exec { "create ${php5_fpm_sock} file":
    command => "touch ${php5_fpm_sock} && chmod 777 ${php5_fpm_sock}",
    onlyif  => ["test ! -f ${php5_fpm_sock}", "test ! -f ${php5_fpm_sock}="],
    require => Package['nginx']
  }

  exec { "listen = 127.0.0.1:9000 => listen = ${php5_fpm_sock}":
    command => "perl -p -i -e 's#listen = 127.0.0.1:9000#listen = ${php5_fpm_sock}#gi' /etc/php-fpm.d/www.conf",
    unless  => "grep -c 'listen = 127.0.0.1:9000' '${php5_fpm_sock}'",
    notify  => [
      Class['nginx::service'],
      Service['php-fpm']
    ],
    require => Exec["create ${php5_fpm_sock} file"]
  }
}

## Begin PHP manifest

if $php_values == undef {
  $php_values = hiera('php', false)
}

if $apache_values == undef {
  $apache_values = hiera('apache', false)
}

if $nginx_values == undef {
  $nginx_values = hiera('nginx', false)
}

Class['Php'] -> Class['Php::Devel'] -> Php::Module <| |> -> Php::Pear::Module <| |> -> Php::Pecl::Module <| |>

if $php_prefix == undef {
  $php_prefix = $::operatingsystem ? {
    /(?i:Ubuntu|Debian|Mint|SLES|OpenSuSE)/ => 'php5-',
    default                                 => 'php-',
  }
}

if $php_fpm_ini == undef {
  $php_fpm_ini = $::operatingsystem ? {
    /(?i:Ubuntu|Debian|Mint|SLES|OpenSuSE)/ => '/etc/php5/fpm/php.ini',
    default                                 => '/etc/php.ini',
  }
}

if is_hash($apache_values) {
  include apache::params

  $php_webserver_service = 'httpd'
  $php_webserver_user = $apache::params::user
  $php_webserver_restart = true


  class { 'php':
    service => $php_webserver_service
  }
} elsif is_hash($nginx_values) {
  include nginx::params

  $php_webserver_service = "${php_prefix}fpm"
  $php_webserver_user = $nginx::params::nx_daemon_user
  $php_webserver_restart = true

  class { 'php':
    package             => $php_webserver_service,
    service             => $php_webserver_service,
    service_autorestart => false,
    config_file         => $php_fpm_ini,
  }

  service { $php_webserver_service:
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => Package[$php_webserver_service]
  }
} else {
  $php_webserver_service = undef
  $php_webserver_restart = false

  class { 'php':
    package             => "${php_prefix}cli",
    service             => $php_webserver_service,
    service_autorestart => false,
  }
}

class { 'php::devel': }

if count($php_values['modules']['php']) > 0 {
  php_mod { $php_values['modules']['php']:; }
}
if count($php_values['modules']['pear']) > 0 {
  php_pear_mod { $php_values['modules']['pear']:; }
}
if count($php_values['modules']['pecl']) > 0 {
  php_pecl_mod { $php_values['modules']['pecl']:; }
}
if count($php_values['ini']) > 0 {
#  $php_values['ini'].each { |$key, $value|
  each( $php_values['ini'] ) |$key, $value| {
    if is_array($value) {
      each( $php_values['ini'][$key] ) |$innerkey, $innervalue| {
        puphpet::ini { "${key}_${innerkey}":
          entry       => "CUSTOM_${innerkey}/${key}",
          value       => $innervalue,
          php_version => $php_values['version'],
          webserver   => $php_webserver_service
        }
      }
    } else {
      puphpet::ini { $key:
        entry       => "CUSTOM/${key}",
        value       => $value,
        php_version => $php_values['version'],
        webserver   => $php_webserver_service
      }
  }
  }

  if $php_values['ini']['session.save_path'] != undef {
    exec {"mkdir -p ${php_values['ini']['session.save_path']}":
      onlyif  => "test ! -d ${php_values['ini']['session.save_path']}",
    }

    file { $php_values['ini']['session.save_path']:
      ensure  => directory,
      group   => 'www-data',
      mode    => 0775,
      require => Exec["mkdir -p ${php_values['ini']['session.save_path']}"]
    }
  }
}

puphpet::ini { $key:
  entry       => 'CUSTOM/date.timezone',
  value       => $php_values['timezone'],
  php_version => $php_values['version'],
  webserver   => $php_webserver_service
}

define php_mod {
  php::module { $name:
    service_autorestart => $php_webserver_restart,
  }
}
define php_pear_mod {
  php::pear::module { $name:
    use_package         => false,
    service_autorestart => $php_webserver_restart,
  }
}
define php_pecl_mod {
  php::pecl::module { $name:
    use_package         => false,
    service_autorestart => $php_webserver_restart,
  }
}

if $php_values['composer'] == 1 {
  class { 'composer':
    target_dir      => '/usr/local/bin',
    composer_file   => 'composer',
    download_method => 'curl',
    logoutput       => false,
    tmp_path        => '/tmp',
    php_package     => "${php::params::module_prefix}cli",
    curl_package    => 'curl',
    suhosin_enabled => false,
  }
}

## Begin Drush manifest

if $drush_values == undef {
  $drush_values = hiera('drush', false)
}

if $drush_values['install'] != undef and $drush_values['install'] == 1 {
  if ($drush_values['settings']['drush.tag_branch'] != undef) {
    $drush_tag_branch = $drush_values['settings']['drush.tag_branch']
  } else {
    $drush_tag_branch = ''
  }

  ## @see https://drupal.org/node/2165015
  include drush::git::drush

  ## class { 'drush::git::drush':
  ##   git_branch => $drush_tag_branch,
  ##   update     => true,
  ## }
}

## End Drush manifest

## Begin Xdebug manifest


if $xdebug_values == undef {
  $xdebug_values = hiera('xdebug', false)
}

if is_hash($apache_values) {
  $xdebug_webserver_service = 'httpd'
} elsif is_hash($nginx_values) {
  $xdebug_webserver_service = 'nginx'
} else {
  $xdebug_webserver_service = undef
}

if $xdebug_values['install'] != undef and $xdebug_values['install'] == 1 {
  class { 'puphpet::xdebug':
    webserver => $xdebug_webserver_service
  }

  if is_hash($xdebug_values['settings']) and count($xdebug_values['settings']) > 0 {
#    $xdebug_values['settings'].each { |$key, $value|
    each( $xdebug_values['settings'] ) |$key, $value| {
      puphpet::ini { $key:
        entry       => "XDEBUG/${key}",
        value       => $value,
        php_version => $php_values['version'],
        webserver   => $xdebug_webserver_service
      }
    }
  }
}

## Begin MySQL manifest

if $mysql_values == undef {
  $mysql_values = hiera('mysql', false)
}

if $php_values == undef {
  $php_values = hiera('php', false)
}

if $apache_values == undef {
  $apache_values = hiera('apache', false)
}

if $nginx_values == undef {
  $nginx_values = hiera('nginx', false)
}
if is_hash($apache_values) or is_hash($nginx_values) {
  $mysql_webserver_restart = true
} else {
  $mysql_webserver_restart = false
}
if $mysql_values['root_password'] {
  class { 'mysql::server':
    root_password => $mysql_values['root_password'],
  }

  if is_hash($mysql_values['databases']) and count($mysql_values['databases']) > 0 {
    create_resources(mysql_db, $mysql_values['databases'])
  }

  if is_hash($php_values) {
    if $::osfamily == 'redhat' and $php_values['version'] == '53' and ! defined(Php::Module['mysql']) {
      php::module { 'mysql':
        service_autorestart => $mysql_webserver_restart,
      }

    } elsif ! defined(Php::Module['mysqlnd']) {
      php::module { 'mysqlnd':
         service_autorestart => $mysql_webserver_restart,
      }
    }
  }
}

define mysql_db (
  $user,
  $password,
  $host,
  $grant    = [],
  $sql_file = false
) {
  if $name == '' or $password == '' or $host == '' {
    fail( 'MySQL DB requires that name, password and host be set. Please check your settings!' )
  }

  mysql::db { $name:
    user     => $user,
    password => $password,
    host     => $host,
    grant    => $grant,
    sql      => $sql_file,
  }
}

if $mysql_values['phpmyadmin'] == 1 and is_hash($php_values) {
  if $::osfamily == 'debian' {
    if $::operatingsystem == 'ubuntu' {
      apt::key { '80E7349A06ED541C': }
      apt::ppa { 'ppa:nijel/phpmyadmin': require => Apt::Key['80E7349A06ED541C'] }
    }

    $phpMyAdmin_package = 'phpmyadmin'
    $phpMyAdmin_folder = 'phpmyadmin'
  } elsif $::osfamily == 'redhat' {
    $phpMyAdmin_package = 'phpMyAdmin.noarch'
    $phpMyAdmin_folder = 'phpMyAdmin'
  }

  if ! defined(Package[$phpMyAdmin_package]) {
    package { $phpMyAdmin_package:
      require => Class['mysql::server']
    }
  }

  include puphpet::params

  if is_hash($apache_values) {
    $mysql_webroot_location = $puphpet::params::apache_webroot_location
  } elsif is_hash($nginx_values) {
    $mysql_webroot_location = $puphpet::params::nginx_webroot_location

    mysql_nginx_default_conf { 'override_default_conf':
      webroot => $mysql_webroot_location
    }
  }

  file { "${mysql_webroot_location}/phpmyadmin":
    target  => "/usr/share/${phpMyAdmin_folder}",
    ensure  => link,
    replace => 'no',
    require => [
      Package[$phpMyAdmin_package],
      File[$mysql_webroot_location]
    ]
  }
}

define mysql_nginx_default_conf (
  $webroot
) {
  if $php5_fpm_sock == undef {
    $php5_fpm_sock = '/var/run/php5-fpm.sock'
  }

  if $fastcgi_pass == undef {
    $fastcgi_pass = $php_values['version'] ? {
      undef   => null,
      '53'    => '127.0.0.1:9000',
      default => "unix:${php5_fpm_sock}"
    }
  }

  class { 'puphpet::nginx':
    fastcgi_pass => $fastcgi_pass,
    notify       => Class['nginx::service'],
  }
}

if has_key($mysql_values, 'adminer') and $mysql_values['adminer'] == 1 and is_hash($php_values) {
  if is_hash($apache_values) {
    $mysql_adminer_webroot_location = $puphpet::params::apache_webroot_location
  } elsif is_hash($nginx_values) {
    $mysql_adminer_webroot_location = $puphpet::params::nginx_webroot_location
  } else {
    $mysql_adminer_webroot_location = $puphpet::params::apache_webroot_location
  }
}

class { 'puphpet::adminer':
    location => "${mysql_adminer_webroot_location}/adminer",
    owner    => 'www-data'
}

class packs {
  package { "php-mbstring":
    ensure => installed,
  }

  package { "php-opcache":
    ensure => installed,
  }

  package { "php-gd":
    ensure => installed,
  }

  package { "multitail":
    ensure => installed,
  }

  package { "screen":
    ensure => installed,
  }

  exec { "vimm":
    command => "yum -d 0 -e 0 -y install vim",
    returns => [ 0, 1],
  }
}

class { 'nodejs':
  version      => 'v0.10.17',
  make_install => false,
  with_npm     => false,
}

define install_node_npm() {
  wget::fetch { "npm-download-${node_version}":
  source             => 'https://npmjs.org/install.sh',
  nocheckcertificate => true,
  destination        => '/tmp/install.sh',
}

exec { "npm-install-${node_version}":
  command     => 'sh install.sh',
  path        => '/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin',
  cwd         => '/tmp',
  user        => 'root',
  environment => 'clean=yes',
  unless      => 'which npm',
  require     => [
    Wget::Fetch["npm-download-${node_version}"],
    Package['curl'],
  ],
}

file { "${node_target_dir}/npm":
    target  => '/usr/local/bin/npm',
    ensure  => link,
    require => Exec["npm-install-${node_version}"],
  }
}

install_node_npm{ 'default':
  require => Class['nodejs']
}

package { 'redis-commander':
  provider => npm
}

class beanstalkd {
    package { "beanstalkd":
        ensure => installed,
    }

    service { 'beanstalkd':
        ensure     => running,
        enable     => true,
        hasrestart => true,
        hasstatus  => true,
        require    => Package['beanstalkd'],
    }

    exec { 'beanstalk_dash':
        cwd => "/usr/share/nginx/www/html/vhosts/",
        command => "git clone https://github.com/ptrofimov/beanstalk_console.git",
        returns => [ 0, 1, 128],
        path => '/usr/local/bin:/usr/bin:/bin',
    }

    file { 'beanstalk_logs':
        path => '/usr/share/nginx/www/html/vhosts/beanstalk_console/logs/',
        ensure => directory,
        require => Exec['beanstalk_dash'],
    }

    file { 'beanstalk_gitkeep':
        path => '/usr/share/nginx/www/html/vhosts/beanstalk_console/logs/.gitkeep',
        ensure => present,
        require => File['beanstalk_logs'],
    }

    file { 'beanstalk_error_log':
        path => '/usr/share/nginx/www/html/vhosts/beanstalk_console/logs/error.log',
        ensure => present,
        require => File['beanstalk_logs'],
    }
}


package { 'grunt-cli':
  provider => npm
}


class nginx_setup {
  exec { 'ini_files':
    cwd     => "/etc/php.d",
    command => "cp -ir /vagrant/files/php.d/* ./",
  }

  exec { 'conf_files1':
    cwd     => "/etc/nginx/conf.d/",
    command => "rm vhost_autogen.conf",
    path => "/usr/bin:/usr/sbin:/bin:/usr/local/bin",
    require => Exec['ini_files'],
    returns => [ 0, 1, 255 ],
  }

  file {'/etc/ssh/ssh_known_hosts':
      owner => 'vagrant',
      group => 'root',
      mode => 644,
      source => "/vagrant/files/ssh/known_hosts",
  }

  exec { 'conf_files':
    cwd     => "/etc/nginx/conf.d/",
    command => "cp -ir /vagrant/files/nginx/laravel.conf ./laravel.conf",
    path => "/usr/bin:/usr/sbin:/bin:/usr/local/bin",
    require => Exec['ini_files'],
  }

  exec { "nginx":
    command => "service nginx restart && service php-fpm restart",
    require => Exec['conf_files'],
    returns => [ 0, 1 ],
  }

   exec {'users_groups':
    command => "usermod -a -G vagrant nginx && sudo usermod -a -G nginx vagrant && sudo usermod -a -G www-data vagrant"
  }
}

class setup {
  exec { "time":
      command => 'mv /etc/localtime /etc/localtime.bak && ln -s /usr/share/zoneinfo/US/Pacific-New /etc/localtime',
  }

  exec {'composer_install':
       cwd => '/usr/share/nginx/www/html/sandbox',
       command => 'composer install -vvvv',
       path => ['/usr/local/bin','/usr/bin', '/bin', '/sbin'],
       environment =>
             [
               "COMPOSER_HOME=/home/vagrant",
              ],
       logoutput => true,
       returns => [ 0, 1, 2, 255],
       timeout => 0,
       user => 'vagrant',
       require => Exec['time'],
  }

  file { "/vagrant/sandbox/app/storage":
     owner  => "vagrant",
     mode   => 777,
  }

  exec { "migrate":
	cwd => '/usr/share/nginx/www/html/sandbox',
	command => "php artisan migrate:refresh --seed",
	path => "/usr/bin:/usr/sbin:/bin:/usr/local/bin",
	returns => [ 0, 1, 2, 255],
	require => Exec['composer_install'],
  }
}

class laravel_setup {

}

class opcache_dash{
    exec { 'opcache_dash':
        cwd => "/usr/share/nginx/www/html/vhosts/",
        command => "git clone https://github.com/carlosbuenosvinos/opcache-dashboard.git",
        returns => [ 0, 1, 128],
        path => '/usr/local/bin:/usr/bin:/bin',
    }

    file { 'opcache_logs':
        path => '/usr/share/nginx/www/html/vhosts/opcache-dashboard/logs/',
        ensure => directory,
        require => Exec['opcache_dash']
    }

    file { 'opcache_gitkeep':
        path => '/usr/share/nginx/www/html/vhosts/opcache-dashboard/logs/.gitkeep',
        ensure => present,
        require => File['opcache_logs']
    }
}

class supervisord{
    exec { "py_tools":
      command => "yum -d 0 -e 0 -y install python-setuptools",
      returns => [ 0, 1],
    }

    exec { "supervisor_setup":
      command => "easy_install supervisor",
      path => "/usr/bin:/usr/sbin:/bin:/usr/local/bin",
      require => Exec['py_tools'],
    }
}

class vhost_tools{

}

class ohmyzsh {
  package { 'zsh':
      ensure => present,
  }

 exec { 'ohmyzsh::git clone':
    creates => "/home/vagrant/.oh-my-zsh",
    command => "/usr/bin/git clone git://github.com/robbyrussell/oh-my-zsh.git /home/vagrant/.oh-my-zsh",
    user    => vagrant,
    require => Package['zsh']
  }

  exec { "theme":
    cwd     => "/home/vagrant/.oh-my-zsh/",
    command => "cp -ir /vagrant/files/custom/cam.zsh-theme ./themes/cam.zsh-theme",
    path => "/usr/bin:/usr/sbin:/bin:/usr/local/bin",
    require => Exec['ohmyzsh::git clone'],
  }
}

class redis{
    package { "redis":
        ensure => installed,
    }

    service { 'redis':
        ensure     => running,
        enable     => true,
        hasrestart => true,
        hasstatus  => true,
        require    => Package['redis'],
    }
}

class bounce{
    exec { "bounce":
        command => "service nginx restart && service php-fpm restart",
    }
}

class{ 'ohmyzsh': stage => nginx_setup }
class{ 'nginx_setup': stage => nginx_setup }
class{ 'packs': stage => nginx_setup }
class{ 'redis': stage => nginx_setup }

class{ 'setup': stage => postsetup }

class{ 'laravel_setup': stage => database }

class{ 'vhost_tools': stage => vhost_tools }
class{ 'beanstalkd': stage => vhost_tools }
class{ 'supervisord': stage => vhost_tools }
class{ 'opcache_dash': stage => vhost_tools }

class{ 'bounce': stage => bounce }
