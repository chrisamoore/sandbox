Vagrant.configure("2") do |config|
  config.vm.box = "CentOS-6.4-x86_64-v20131103"
  config.vm.box_url = "http://developer.nrel.gov/downloads/vagrant-boxes/CentOS-6.4-x86_64-v20131103.box"

  config.vm.network "private_network", ip: "192.168.56.166"
  config.vm.hostname = "sand.box"

  # Caches
  config.cache.auto_detect = true
  config.cache.scope = :machine
  config.cache.enable :yum
  config.cache.enable :composer
  config.cache.enable :npm

  config.vm.synced_folder "./", "/usr/share/nginx/www/html", id: "vagrant-root", :nfs => true

  config.vm.usable_port_range = (2201..2201)

  config.vm.provider :virtualbox do |virtualbox|
    virtualbox.customize ["modifyvm", :id, "--name", "sandbox"]
    virtualbox.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    virtualbox.customize ["modifyvm", :id, "--memory", "2048"]
    virtualbox.customize ["setextradata", :id, "--VBoxInternal2/SharedFoldersEnableSymlinksCreate/v-root", "1"]
  end

  config.vm.provision :shell, :path => "shell/initial-setup.sh"
  config.vm.provision :shell, :path => "shell/update-puppet.sh"
  config.vm.provision :shell, :path => "shell/librarian-puppet-vagrant.sh"
  config.vm.provision :puppet do |puppet|
    puppet.facter = {
      "ssh_username" => "vagrant"
    }

    puppet.manifests_path = "puppet/manifests"
    puppet.options = ["--verbose", "--hiera_config /vagrant/hiera.yaml", "--parser future"]
  end

  config.ssh.username = "vagrant"

  config.ssh.shell = "bash -l"

  config.ssh.keep_alive = true
  config.ssh.forward_agent = true
  config.ssh.forward_x11 = false
  config.vagrant.host = :detect
end

