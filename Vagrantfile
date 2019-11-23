# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
#  config.vm.box = "ubuntu/trusty64"
  config.vm.box = "ubuntu/disco64"
#   config.vm.box = "ubuntu/xenial64"

  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine
    vb.gui = false

    # Customize the amount of memory on the VM:
    vb.memory = "1024"
  end

  config.vm.provision "shell", inline: <<-SHELL
    sudo apt-get update > /dev/null
  SHELL

  cluster_network = "10.200.0."
  general_external = "10.200.10."
  api_server_ip=""
  controllerNodeCount = 1
  workerNodeCount = 1

  controller_ip_start = 10
  worker_ip_start = 20

  workerNodeIps = "provision_helpers/node_external_ips"
  clusterNodeIps = "provision_helpers/node_internal_ips"
  sharedProvisionVars = "/home/vagrant/shared/provision_helpers/shared_vars.sh"
  controllerProvScript = "/home/vagrant/shared/provision_helpers/controller-node-provision.sh"
  workerProvScript = "/home/vagrant/shared/provision_helpers/worker-node-provision.sh"

  # include a directory of all valid controller-node IPs
  open('provision_helpers/node_external_ips', 'w') { |f|
      (1..controllerNodeCount).each do |j|
          hostname = "controller-#{j}"
          control_node_ip = general_external + controller_ip_start.to_s
          control_cluster_ip = cluster_network + controller_ip_start.to_s
          controller_ip_start += 1

          divider = " "
          if j == controllerNodeCount
              divider = "\n"
          end

          f << "#{control_node_ip},#{hostname}#{divider}"
      end
  }

  # include a directory of all valid worker-node IPs
  open('provision_helpers/node_external_ips', 'a') { |f|
      (1..workerNodeCount).each do |j|
          hostname = "worker-#{j}"
          work_node_ip = general_external + worker_ip_start.to_s
          work_cluster_ip = cluster_network + worker_ip_start.to_s
          worker_ip_start += 1

          divider = " "
          if j == workerNodeCount
              divider = "\n"
          end

          f << "#{work_node_ip},#{hostname}#{divider}"
      end
  }

  # REMINDERS:
  # change the /etc/rsolv.conf nameserver IP to match with the one im using
  controller_ip_start = 10
  worker_ip_start = 20

  (1..controllerNodeCount).each do |i|
      config.vm.define "kthw-controller-#{i}" do |c|
          hostname = "controller-#{i}"
          c.vm.hostname = hostname
          c.vm.synced_folder "pki/", "/home/vagrant/shared/pki"
          c.vm.synced_folder "bin/", "/home/vagrant/shared/bin"
          c.vm.synced_folder "provision_helpers/", "/home/vagrant/shared/provision_helpers"

          node_ip = general_external + controller_ip_start.to_s

          # Only works with one controller node
          api_server_ip = node_ip

          cluster_ip = cluster_network + controller_ip_start.to_s
          controller_ip_start += 1
          c.vm.network "private_network", ip: cluster_ip, virtualbox__intnet: "clusternetwork"
          c.vm.network "private_network", ip: node_ip

          c.vm.provision "shell", inline: <<-SHELL
            sed -i.bak -E 's/(HOSTFROMFILE=)(.*)/\\1#{hostname}/' #{controllerProvScript}
            sed -i.bak -E 's/(EXTERNAL_IP=)(.*)/\\1#{node_ip}/' #{controllerProvScript}
            sed -i.bak -E 's/(INTERNAL_IP=)(.*)/\\1#{cluster_ip}/' #{controllerProvScript}
          SHELL

          c.vm.provision "shell", path: "provision_helpers/controller-node-provision.sh"
      end
  end

  (1..workerNodeCount).each do |i|
      config.vm.define "kthw-worker-#{i}" do |n|
          hostname = "worker-#{i}"
          n.vm.hostname = hostname
          n.vm.synced_folder "pki/", "/home/vagrant/shared/pki"
          n.vm.synced_folder "bin/", "/home/vagrant/shared/bin"
          n.vm.synced_folder "provision_helpers/", "/home/vagrant/shared/provision_helpers"

          node_ip = general_external + worker_ip_start.to_s
          cluster_ip = cluster_network + worker_ip_start.to_s
          worker_ip_start += 1
          n.vm.network "private_network", ip: cluster_ip, virtualbox__intnet: "clusternetwork"
          n.vm.network "private_network", ip: node_ip

          n.vm.provision "shell", inline: <<-SHELL
            sed -i.bak -E 's/(HOSTFROMFILE=)(.*)/\\1#{hostname}/' #{workerProvScript}
            sed -i.bak -E 's/(EXTERNAL_IP=)(.*)/\\1#{node_ip}/' #{workerProvScript}
            sed -i.bak -E 's/(INTERNAL_IP=)(.*)/\\1#{cluster_ip}/' #{workerProvScript}
            sed -i.bak -E 's/(API_SERVER_IP=)(.*)/\\1#{api_server_ip}/' #{workerProvScript}
          SHELL

          n.vm.provision "shell", path: "provision_helpers/worker-node-provision.sh"
      end
  end

end
