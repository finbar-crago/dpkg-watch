# -*- mode: ruby -*-
Vagrant.configure("2") do |config|
  config.vm.box = "debian/jessie64"
  config.vm.network "forwarded_port", guest: 3000, host: 3000
  config.vm.provision "shell", inline: <<-SHELL
     apt-get update
     apt-get install -y screen libmojolicious-perl
     screen -dm perl /vagrant/dpkg-watch.pl
     echo "--> http://127.0.0.1:3000/"
   SHELL
end
