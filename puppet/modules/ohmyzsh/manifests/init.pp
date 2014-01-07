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