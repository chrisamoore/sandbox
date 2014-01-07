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