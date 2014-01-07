class opcache_dash{
    exec { 'opcache_dash':
        cwd => "/usr/share/nginx/www/html/vhosts/",
        command => "git clone https://github.com/carlosbuenosvinos/opcache-dashboard.git",
        returns => [ 0, 1],
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
include opcache_dash
