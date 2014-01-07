class varnish{
    package { "varnish":
        ensure => installed,
    }
}

include varnish