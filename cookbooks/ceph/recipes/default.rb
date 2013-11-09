directory "/opt/ceph"
  action :create
  recursive true
end

cookbook_file "/opt/cephdev.sh" do
  source "cephdev.sh"
end

execute "run cephdev" do
  command "/bin/bash /opt/cephdev.sh /opt/ceph"
end
