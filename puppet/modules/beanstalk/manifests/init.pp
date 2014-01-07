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
        returns => [ 0, 1],
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

include beanstalkd