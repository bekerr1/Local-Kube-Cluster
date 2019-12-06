#!/bin/bash

# ------------------------------- UTILITIES -------------------------------
sudo swapoff -a > /dev/null
sudo iptables -P FORWARD ACCEPT
#sudo apt-get remove docker docker-engine docker.io > /dev/null
#sudo apt-get install -y docker.io > /dev/null
#
#echo " ************ Verifying Docker ************ "
#sudo docker run hello-world

# ------------------------------- KUBECTL -------------------------------
# Install kubectl
if [ ! -d "/home/vagrant/shared/bin/kubectl" ]; then
    {
        mkdir -p /home/vagrant/shared/bin/kubectl
        cd /home/vagrant/shared/bin/kubectl

        echo " ************ Downloading kubectl binary ************ "
        wget -q https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kubectl > /dev/null

        chmod +x kubectl
        sudo cp kubectl /usr/local/bin/
        cd -
    }
else
    {
        cd /home/vagrant/shared/bin/kubectl

        echo " ************ Copying kubectl from shared bin folder ************ "
        sudo cp kubectl /usr/local/bin/

        cd -
    }
fi

# ------------------------------- PKI INFRA START -------------------------------
# Tools to provision PKI infrastructure and generate TLS certificates
if [ ! -d "/home/vagrant/shared/bin/pki" ]; then
    {
        mkdir -p /home/vagrant/shared/bin/pki
        cd /home/vagrant/shared/bin/pki

        echo " ************ Downloading PKI tools ************ "
        wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 \
            https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 > /dev/null

        chmod +x cfssl_linux-amd64 cfssljson_linux-amd64
        sudo cp cfssl_linux-amd64 /usr/local/bin/cfssl
        sudo cp cfssljson_linux-amd64 /usr/local/bin/cfssljson
        cd -
    }
else
    {
        cd /home/vagrant/shared/bin/pki

        echo " ************ Copying PKI tools from shared bin folder ************ "
        sudo cp cfssl_linux-amd64 /usr/local/bin/cfssl
        sudo cp cfssljson_linux-amd64 /usr/local/bin/cfssljson

        cd -
    }
fi

# ------------------------------- ETCD CONFIG START -------------------------------
if [ ! -d "/home/vagrant/shared/bin/etcd" ]; then
    {
        mkdir -p /home/vagrant/shared/bin/etcd
        cd /home/vagrant/shared/bin/etcd

        echo " ************ Downloading etcd binary ************ "
        wget -q --https-only --timestamping \
            https://github.com/coreos/etcd/releases/download/v3.3.9/etcd-v3.3.9-linux-amd64.tar.gz > /dev/null

        tar -xvf etcd-v3.3.9-linux-amd64.tar.gz
        cp -r etcd-v3.3.9-linux-amd64/etcd* .
        rm -rf etcd-v3.3.9-linux-amd64/
        sudo cp -r etcd* /usr/local/bin/
        cd -
    }
else
    {
        cd /home/vagrant/shared/bin/etcd

        echo " ************ Copying etcd binary from shared bin ************ "
        sudo cp -r etcd* /usr/local/bin/

        cd -
    }
fi

# ------------------------------- CONTROL PLANE -------------------------------
sudo mkdir -p /etc/kubernetes/config
if [ ! -d "/home/vagrant/shared/bin/controller" ]; then
    {
        sudo mkdir -p /home/vagrant/shared/bin/controller
        cd /home/vagrant/shared/bin/controller

        echo " ************ Download kubernetes controller binaries ************ "
        wget -q --https-only --timestamping \
            https://dl.k8s.io/v1.14.0-rc.1/kubernetes-server-linux-amd64.tar.gz > /dev/null

        tar -xvzf kubernetes-server-linux-amd64.tar.gz
        ls -d kubernetes/server/bin/* | grep -E 'kubernetes/server/bin/kube*[^.]+$' | xargs -I {} cp {} .
        rm -rf kubernetes
        chmod +x kube-apiserver kube-controller-manager kube-scheduler
        sudo cp kube-apiserver kube-controller-manager kube-scheduler /usr/local/bin/
        cd -
    }
else
    {
        cd /home/vagrant/shared/bin/controller
        echo " ************ Copying kubernetes controller binaries from shared bin ************ "
        sudo cp kube-apiserver kube-controller-manager kube-scheduler /usr/local/bin/
        cd -
    }
fi

# ------------------------------- WORKER PLANE -------------------------------
if [ ! -d "/home/vagrant/shared/bin/worker" ]; then
    {
        mkdir -p /home/vagrant/shared/bin/worker
        sudo mkdir -p /opt/cni/bin
        cd /home/vagrant/shared/bin/worker
        echo " ************ Downloading worker node binaries ************ "
        wget -q --https-only --timestamping \
            https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.12.0/crictl-v1.12.0-linux-amd64.tar.gz \
            https://storage.googleapis.com/gvisor/releases/nightly/latest/runsc \
            https://github.com/opencontainers/runc/releases/download/v1.0.0-rc5/runc.amd64 \
            https://github.com/containernetworking/plugins/releases/download/v0.6.0/cni-plugins-amd64-v0.6.0.tgz \
            https://github.com/containerd/containerd/releases/download/v1.2.0-rc.0/containerd-1.2.0-rc.0.linux-amd64.tar.gz \
            https://dl.k8s.io/v1.14.0-rc.1/kubernetes-node-linux-amd64.tar.gz

        tar -xvf crictl-v1.12.0-linux-amd64.tar.gz
        tar -xvf cni-plugins-amd64-v0.6.0.tgz
        tar -xvf containerd-1.2.0-rc.0.linux-amd64.tar.gz
        tar -xvf kubernetes-node-linux-amd64.tar.gz
        cp kubernetes/node/bin/* ./
        cp runc.amd64 runc
        chmod +x kubectl kube-proxy kubelet kubeadm runc runsc crictl
        sudo cp kubectl kube-proxy kubelet kubeadm runc runsc crictl /usr/local/bin/
        sudo cp bin/* /usr/local/bin/
        sudo cp flannel ptp host-local portmap tuning vlan sample dhcp ipvlan macvlan loopback bridge /opt/cni/bin
        cd -
    }
else
    {
        cd /home/vagrant/shared/bin/worker

        echo " ************ Copying worker node binaries from shared bin ************ "
        sudo mkdir -p /opt/cni/bin
        sudo cp kubectl kube-proxy kubelet kubeadm runc runsc crictl /usr/local/bin/
        sudo cp bin/* /usr/local/bin/
        sudo cp flannel ptp host-local portmap tuning vlan sample dhcp ipvlan macvlan loopback bridge /opt/cni/bin

        cd -
    }
fi
# ------------------------------- UTILITIES -------------------------------
if [ ! -d "/home/vagrant/shared/bin/utilities" ]; then
    {
        echo " ************ Installing various utilities ************ "
        mkdir -p /home/vagrant/shared/bin/utilities
        cd /home/vagrant/shared/bin/utilities

        echo "      Downloading skaffold"
        curl -s -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64 > /dev/null
        chmod +x skaffold
        sudo cp skaffold /usr/local/bin

        cd -
    }
else
    {
        echo "Copying installed utilities from shared bin"
        cd /home/vagrant/shared/bin/utilities
        sudo cp skaffold /usr/local/bin
        cd -
    }
fi
