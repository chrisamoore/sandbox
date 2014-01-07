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

include redis
