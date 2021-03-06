Sand Box
==========

###CENTOS 6.4 LEMP
####Prereqs:
- [Vagrant 1.3.5](http://files.vagrantup.com/packages/a40522f5fabccb9ddabad03d836e120ff5d14093/Vagrant-1.3.5.dmg)

- [Virtualbox 4.3.2](http://download.virtualbox.org/virtualbox/4.3.2/VirtualBox-4.3.2-90405-OSX.dmg)
 
- VBguest - 0.10<br>
	`vagrant plugin install vagrant-vbguest`<br>	
- Cachier 0.5.0<br>
	`vagrant plugin install vagrant-cachier`
	
- Cache the box <br>
	`vagrant box add CentOS-6.4-x86_64-v20131103 http://developer.nrel.gov/downloads/vagrant-boxes/CentOS-6.4-x86_64-v20131103.box`

- Add this to /etc/hosts

		192.168.56.166 sand.box 

####Run `vagrant up`
- PHP-FPM 
- NGINX
- php 5.5+
- MySQL
- Redis extension
- Redis
- Redis-commander
- Opcache
- Opcache Console
- beanstalk
- beanstalk console
- Supervisord

###Connect to MySQL 
![https://dl-web.dropbox.com/get/Screenshots/Screen%20Shot%202013-12-07%20at%202.42.52%20PM.png?w=AACkcnHR67R2-znevdiWvii1IzGcD4_a4oz35P7NLr13CQ](https://dl-web.dropbox.com/get/Screenshots/Screen%20Shot%202013-12-07%20at%202.42.52%20PM.png?w=AACkcnHR67R2-znevdiWvii1IzGcD4_a4oz35P7NLr13CQ)

- MySQL Host Pass `root` <br>
- SSH Host Pass `vagrant` <br>
- Port 2201
