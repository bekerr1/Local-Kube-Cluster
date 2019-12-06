#!/bin/bash

source /home/vagrant/shared/provision_helpers/shared_vars.sh
source /home/vagrant/shared/provision_helpers/worker_vars.sh

echo " ************ Binary Versions ************ "
containerd --version
runc --version
runsc --version

HOSTFROMFILE=worker-2
EXTERNAL_IP=192.168.10.21
INTERNAL_IP=192.168.0.21
API_SERVER_IP=192.168.10.10

echo "Provisioning Node $HOSTFROMFILE with \
ExternalIP: $EXTERNAL_IP and \
InternalIP: $INTERNAL_IP and \
API_SERVER_IP: $API_SERVER_IP"

# configure /etc/hosts
WORKER_HOSTNAME_IP=$(grep worker $CLUSTER_IPS)
for ip in $WORKER_HOSTNAME_IP
do
    host_ip_pair=$(echo $ip | sed 's/,/ /g')
    echo $host_ip_pair | sudo tee -a /etc/hosts > /dev/null
done

CONTROLLER_HOSTNAME_IPS=$(grep controller $CLUSTER_IPS)
for ip in $CONTROLLER_HOSTNAME_IPS
do
    host_ip_pair=$(echo $ip | sed 's/,/ /g')
    echo $host_ip_pair | sudo tee -a /etc/hosts > /dev/null
done

GENCERTS=
echo " ************ PKI Infrastructure ************ "
if [ ! -f "$WORKER_CSR" ]; then
    echo "----> Generating $WORKER_CSR"
    mkdir -p $WORKER_PATH
    cat > ${WORKER_CSR} <<EOF
{
  "CN": "system:node:${HOSTNAME}",
  "key": {
    "algo": "rsa",
    "size": 2048
},
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:nodes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
  }
  ]
}
EOF
    GENCERTS=true
fi

if [ "$GENCERTS" = true ]; then
    echo "----> Generating Worker key pair"
    cfssl gencert \
        -ca=${CA} \
        -ca-key=${CA_KEY} \
        -config=${CA_CONFIG} \
        -hostname=${HOSTNAME},${EXTERNAL_IP},${INTERNAL_IP} \
        -profile=kubernetes \
        ${WORKER_CSR} | cfssljson -bare ${WORKER_PATH}/${HOSTNAME} > /dev/null
else
    echo "----> No work to do for ${HOSTNAME} certificates"
fi

echo "----> BUILDING ${HOSTNAME}.kubeconfig"
kubectl config set-cluster $NETWORK_NAME \
    --server=https://${API_SERVER_IP}:6443 \
    --certificate-authority=${CA} \
    --embed-certs=true \
    --kubeconfig=${HOSTNAME}.kubeconfig > /dev/null

kubectl config set-credentials system:node:${HOSTNAME} \
    --client-certificate=${WORKER_CA} \
    --client-key=${WORKER_KEY} \
    --embed-certs=true \
    --kubeconfig=${HOSTNAME}.kubeconfig > /dev/null

kubectl config set-context default \
    --cluster=$NETWORK_NAME \
    --user=system:node:${HOSTNAME} \
    --kubeconfig=${HOSTNAME}.kubeconfig > /dev/null

kubectl config use-context default --kubeconfig=${HOSTNAME}.kubeconfig > /dev/null

echo "----> BUILDING kube-proxy.kubeconfig"
kubectl config set-cluster $NETWORK_NAME \
    --server=https://${API_SERVER_IP}:6443 \
    --certificate-authority=${CA} \
    --embed-certs=true \
    --kubeconfig=kube-proxy.kubeconfig > /dev/null

kubectl config set-credentials system:kube-proxy \
    --client-certificate=${KUBE_PROXY_PATH}/kube-proxy.pem \
    --client-key=${KUBE_PROXY_PATH}/kube-proxy-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-proxy.kubeconfig > /dev/null

kubectl config set-context default \
    --cluster=$NETWORK_NAME \
    --user=system:kube-proxy \
    --kubeconfig=kube-proxy.kubeconfig > /dev/null

kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig > /dev/null

## ------------------------------- WORKER PLANE CONFIG START -------------------------------
sudo mkdir -p \
    /etc/cni/net.d \
    /opt/cni/bin \
    /var/lib/kubelet \
    /var/lib/kube-proxy \
    /var/lib/kubernetes

echo " ************ Bridge CNI config ************ "
cat <<EOF | sudo tee /etc/cni/net.d/10-bridge.conf > /dev/null
{
    "cniVersion": "0.3.1",
    "name": "bridge",
    "type": "bridge",
    "bridge": "cnio0",
    "isGateway": true,
    "ipMasq": true,
    "ipam": {
        "type": "host-local",
        "ranges": [
          [{"subnet": "${POD_CIDR}"}]
        ],
        "routes": [{"dst": "0.0.0.0/0"}]
    }
}
EOF

echo " ************ Loopback CNI config ************ "
cat <<EOF | sudo tee /etc/cni/net.d/99-loopback.conf > /dev/null
{
    "cniVersion": "0.3.1",
    "type": "loopback"
}
EOF

echo " ************ Create containerd config ************ "
sudo mkdir -p /etc/containerd/
cat << EOF | sudo tee /etc/containerd/config.toml > /dev/null
[plugins]
  snapshotter = "overlayfs"
  [plugins.cri.containerd]
    [plugins.cri.containerd.default_runtime]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/local/bin/runc"
      runtime_root = ""
    [plugins.cri.containerd.untrusted_workload_runtime]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/local/bin/runsc"
      runtime_root = "/run/containerd/runsc"
    [plugins.cri.containerd.gvisor]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/local/bin/runsc"
      runtime_root = "/run/containerd/runsc"
EOF

echo " ************ Create crictl config ************ "
cat << EOF | sudo tee /etc/crictl.yaml > /dev/null
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: true
EOF

echo " ************ Setup required sysctl params ************ "
cat > /etc/sysctl.d/99-kubernetes-cri.conf <<EOF
  net.ipv4.ip_forward                 = 1
EOF

echo " ************ Create containerd.service systemd unit file ************ "
cat <<EOF | sudo tee /etc/systemd/system/containerd.service > /dev/null
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target

[Service]
ExecStartPre=/sbin/modprobe overlay
ExecStartPre=/sbin/modprobe br_netfilter
ExecStart=/usr/local/bin/containerd
Restart=always
RestartSec=5
Delegate=yes
KillMode=process
OOMScoreAdjust=-999
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF

sudo cp ${WORKER_KEY} ${WORKER_CA} /var/lib/kubelet/
sudo cp ${HOSTNAME}.kubeconfig /var/lib/kubelet/kubeconfig
sudo cp ${CA_PATH}/ca.pem ${CA_PATH}/ca-key.pem /var/lib/kubernetes/

echo " ************ Create the kubelet-config.yaml config file ************ "
cat <<EOF | sudo tee /var/lib/kubelet/kubelet-config.yaml > /dev/null
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: "/var/lib/kubernetes/ca.pem"
authorization:
  mode: Webhook
clusterDNS:
  - "${DNS_POD_IP}"
clusterDomain: "cluster.local"
resolvConf: "/run/systemd/resolve/resolv.conf"
podCIDR: "${POD_CIDR}"
runtimeRequestTimeout: "15m"
tlsCertFile: "/var/lib/kubelet/${HOSTNAME}.pem"
tlsPrivateKeyFile: "/var/lib/kubelet/${HOSTNAME}-key.pem"
EOF

echo " ************ Create the kubelet systemd unit file ************ "
cat <<EOF | sudo tee /etc/systemd/system/kubelet.service > /dev/null
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=containerd.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config=/var/lib/kubelet/kubelet-config.yaml \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --container-runtime=remote \\
  --container-runtime-endpoint=unix:///run/containerd/containerd.sock \\
  --node-ip=${EXTERNAL_IP} \\
  --network-plugin=cni \\
  --register-node=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo cp kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig

echo " ************ Create kube-proxy-config.yaml config file ************ "
cat <<EOF | sudo tee /var/lib/kube-proxy/kube-proxy-config.yaml > /dev/null
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: "/var/lib/kube-proxy/kubeconfig"
mode: "iptables"
clusterCIDR: "${CLUSTER_CIDR}"
EOF

echo " ************ Create the kube-proxy.service systemd unit file ************ "
cat <<EOF | sudo tee /etc/systemd/system/kube-proxy.service > /dev/null
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-proxy \\
  --config=/var/lib/kube-proxy/kube-proxy-config.yaml \\
  --v=4
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable containerd kubelet kube-proxy
echo " ************ Start the worker node services ************ "
{
    sudo systemctl daemon-reload
    sudo systemctl enable kubelet kube-proxy
    sudo systemctl start containerd kubelet kube-proxy
}

echo " ************ Setting up kubectl context ************ "
/home/vagrant/shared/provision_helpers/utilities/internal_kubectl_setup.sh $NETWORK_NAME $CA $API_SERVER_IP $ADMIN_CA $ADMIN_KEY
kubectl get nodes

# for kubernetes user
kubectl create clusterrolebinding me-cluster-admin \
    --clusterrole=cluster-admin \
    --user=kubernetes

# experimental. This seems to be needed...
sudo iptables -P FORWARD ACCEPT

