Vagrant.configure("2") do |config|
  config.vm.hostname = "ceph-swift"
  config.vm.box = "ceph-swift"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"
  config.vm.provider :virtualbox do |vb|
    vb.name = "ceph-swift-%d" % Time.now
  end
  config.vm.provision :chef_solo do |chef|
    chef.add_recipe "swift"
    chef.add_recipe "ceph"
  end
end
