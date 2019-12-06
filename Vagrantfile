# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
    config.vm.box = "hashicorp/bionic64"
    config.vm.provider "vmware_fusion" do |vb|
        vb.gui = false
        vb.memory = "1024"
    end

    config.vm.provision "shell", inline: <<-SHELL
      sudo apt-get update > /dev/null
    SHELL

    controllerNodeCount = 1
    workerNodeCount = 2

    api_server_ip="192.168.10.10"
    internal_ip_part = "192.168.0."
    external_ip_part = "192.168.10."
    controller_ip_start = 10
    worker_ip_start = 20

    externalNodeIps = "shared/provision_helpers/node_external_ips"
    internalNodeIps = "shared/provision_helpers/node_internal_ips"

    # Include a directory of all valid controller-node IPs
    nodeIps = ""
    (1..controllerNodeCount).each do |j|
        hostname = "controller-#{j}"
        control_node_ip = external_ip_part + controller_ip_start.to_s
        control_cluster_ip = internal_ip_part + controller_ip_start.to_s
        controller_ip_start += 1

        divider = " "
        if j == controllerNodeCount
            divider = "\n"
        end

        nodeIps += "#{control_node_ip},#{hostname}#{divider}"
    end

    # Include a directory of all valid worker-node IPs
    (1..workerNodeCount).each do |j|
         hostname = "worker-#{j}"
         work_node_ip = external_ip_part + worker_ip_start.to_s
         work_cluster_ip = internal_ip_part + worker_ip_start.to_s
         worker_ip_start += 1

         divider = " "
         if j == workerNodeCount
             divider = "\n"
         end

         nodeIps += "#{work_node_ip},#{hostname}#{divider}"
    end
    File.write(externalNodeIps, nodeIps)

    # REMINDERS:
    # change the /etc/rsolv.conf nameserver IP to match with the one im using
    controller_ip_start = 10
    worker_ip_start = 20

    sharedProvisionVars = "/home/vagrant/shared/provision_helpers/shared_vars.sh"
    controllerProvScript = "/home/vagrant/shared/provision_helpers/controller-node-provision.sh"
    workerProvScript = "/home/vagrant/shared/provision_helpers/worker-node-provision.sh"

    (1..controllerNodeCount).each do |i|
        config.vm.define "kthw-controller-#{i}" do |c|
            hostname = "controller-#{i}"

            c.vm.hostname = hostname
            c.vm.synced_folder "shared/", "/home/vagrant/shared/"

            node_ip = external_ip_part + controller_ip_start.to_s
            cluster_ip = internal_ip_part + controller_ip_start.to_s
            controller_ip_start += 1

            c.vm.network "private_network", ip: cluster_ip, virtualbox__intnet: "clusternetwork"
            c.vm.network "private_network", ip: node_ip

            c.vm.provision "shell", inline: <<-SHELL
              sed -i.bak -E 's/(HOSTFROMFILE=)(.*)/\\1#{hostname}/' #{controllerProvScript}
              sed -i.bak -E 's/(EXTERNAL_IP=)(.*)/\\1#{node_ip}/' #{controllerProvScript}
              sed -i.bak -E 's/(INTERNAL_IP=)(.*)/\\1#{cluster_ip}/' #{controllerProvScript}
            SHELL

            c.vm.synced_folder "shared/", "/home/vagrant/shared/"

            c.vm.provision "shell", path: "shared/provision_helpers/kube-bin-provision.sh"
            c.vm.provision "shell", path: "shared/provision_helpers/controller-node-provision.sh"
        end
    end

    (1..workerNodeCount).each do |i|
        config.vm.define "kthw-worker-#{i}" do |n|
            hostname = "worker-#{i}"

            n.vm.hostname = hostname
            n.vm.synced_folder "shared/", "/home/vagrant/shared/"

            node_ip = external_ip_part + worker_ip_start.to_s
            cluster_ip = internal_ip_part + worker_ip_start.to_s
            worker_ip_start += 1

            n.vm.network "private_network", ip: cluster_ip, virtualbox__intnet: "clusternetwork"
            n.vm.network "private_network", ip: node_ip

            n.vm.provision "shell", inline: <<-SHELL
              sed -i.bak -E 's/(HOSTFROMFILE=)(.*)/\\1#{hostname}/' #{workerProvScript}
              sed -i.bak -E 's/(EXTERNAL_IP=)(.*)/\\1#{node_ip}/' #{workerProvScript}
              sed -i.bak -E 's/(INTERNAL_IP=)(.*)/\\1#{cluster_ip}/' #{workerProvScript}
              sed -i.bak -E 's/(API_SERVER_IP=)(.*)/\\1#{api_server_ip}/' #{workerProvScript}
            SHELL

            n.vm.synced_folder "shared/", "/home/vagrant/shared/"

            n.vm.provision "shell", path: "shared/provision_helpers/kube-bin-provision.sh"
            n.vm.provision "shell", path: "shared/provision_helpers/worker-node-provision.sh"
        end
    end
end
