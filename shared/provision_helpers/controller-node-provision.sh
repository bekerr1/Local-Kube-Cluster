#!/bin/bash

source /home/vagrant/shared/provision_helpers/shared_vars.sh
source /home/vagrant/shared/provision_helpers/controller_vars.sh

echo " ************ Binary Versions ************ "
etcd --version
etcdctl --version
kubectl version
echo "API Server"
kube-apiserver --version
echo "Controller manager"
kube-controller-manager --version
echo "Scheduler"
kube-scheduler --version

HOSTFROMFILE=controller-1
EXTERNAL_IP=192.168.10.10
INTERNAL_IP=192.168.0.10

echo "Provisioning Node $HOSTFROMFILE with \
ExternalIP: $EXTERNAL_IP and \
InternalIP: $INTERNAL_IP"

# configure /etc/hosts
echo " ************ /etc/hosts CONFIG ************ "
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

echo " ************ Creating PKI directories ************ "
mkdir -p $CA_PATH
mkdir -p $ADMIN_PATH
mkdir -p $API_SERVER_PATH
mkdir -p $CTRLR_MGR_PATH
mkdir -p $KUBE_PROXY_PATH
mkdir -p $SCHEDULER_PATH
mkdir -p $SERVICE_ACCOUNT_PATH

GENCERTS=
echo " ************ PKI Infrastructure ************ "
if [ ! -f "$CA_CONFIG" ]; then
    echo "----> Generating $CA_CONFIG"
    cat > $CA_CONFIG <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF
fi

if [ ! -f "$CA_CSR" ]; then
    echo "----> Generating $CA_CSR"
    cat > $CA_CSR <<EOF
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "CA",
      "ST": "Oregon"
    }
  ]
}
EOF
    GENCERTS=true
fi

if [ "$GENCERTS" = true ]; then
    echo "----> Generating $CA_CSR certificate"
    cfssl gencert -initca ${CA_CSR} | cfssljson -bare ${CA_PATH}/ca > /dev/null
else
    echo "----> No work to do for ${CA_CSR} certificates"
fi

GENCERTS=
if [ ! -f "$ADMIN_CSR" ]; then
    echo "----> Generating $ADMIN_CSR"
    cat > ${ADMIN_CSR} <<EOF
{
  "CN": "admin",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:masters",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF
    GENCERTS=true
fi

if [ "$GENCERTS" = true ]; then
    echo "----> Generating $ADMIN_CSR certificate"
    cfssl gencert \
        -ca=${CA_PATH}/ca.pem \
        -ca-key=${CA_PATH}/ca-key.pem \
        -config=${CA_CONFIG} \
        -profile=${CA_PROFILE} \
        ${ADMIN_CSR} | cfssljson -bare ${ADMIN_PATH}/admin > /dev/null
else
    echo "----> No work to do for $ADMIN_CSR certificates"
fi

GENCERTS=
if [ ! -f "$CTRLR_MGR_CSR" ]; then
    echo "----> Generating $CTRLR_MGR_CSR"
    cat > ${CTRLR_MGR_CSR} <<EOF
{
  "CN": "system:kube-controller-manager",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:kube-controller-manager",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF
    GENCERTS=true
fi

if [ "$GENCERTS" = true ]; then
    echo "----> Generating $CTRLR_MGR_CSR certificate"
    cfssl gencert \
        -ca=${CA_PATH}/ca.pem \
        -ca-key=${CA_PATH}/ca-key.pem \
        -config=${CA_CONFIG} \
        -profile=${CA_PROFILE} \
        ${CTRLR_MGR_CSR} | cfssljson -bare ${CTRLR_MGR_PATH}/kube-controller-manager > /dev/null
else
    echo "----> No work to do for $CTRLR_MGR_CSR  certificates"
fi

GENCERTS=
if [ ! -f "$KUBE_PROXY_CSR" ]; then
    echo "----> Generating $KUBE_PROXY_CSR"
    cat > ${KUBE_PROXY_CSR} <<EOF
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:node-proxier",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF
    GENCERTS=true
fi


if [ "$GENCERTS" = true ]; then
    echo "----> Generating $KUBE_PROXY_CSR certificate"
    cfssl gencert \
        -ca=${CA_PATH}/ca.pem \
        -ca-key=${CA_PATH}/ca-key.pem \
        -config=${CA_CONFIG} \
        -profile=${CA_PROFILE} \
        ${KUBE_PROXY_CSR} | cfssljson -bare ${KUBE_PROXY_PATH}/kube-proxy > /dev/null
else
    echo "----> No work to do for $KUBE_PROXY_CSR certificates"
fi

GENCERTS=
if [ ! -f "$SCHEDULER_CSR" ]; then
    echo "----> Generating $SCHEDULER_CSR"
    cat > ${SCHEDULER_CSR} <<EOF
{
  "CN": "system:kube-scheduler",
  "key": {
    "algo": "rsa",
    "size": 2048
},
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:kube-scheduler",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF
    GENCERTS=true
fi

if [ "$GENCERTS" = true ]; then
    echo "----> Generating $SCHEDULER_CSR certificate"
    cfssl gencert \
        -ca=${CA_PATH}/ca.pem \
        -ca-key=${CA_PATH}/ca-key.pem \
        -config=${CA_CONFIG} \
        -profile=${CA_PROFILE} \
        ${SCHEDULER_CSR} | cfssljson -bare ${SCHEDULER_PATH}/kube-scheduler > /dev/null
else
    echo "----> No work to do for $SCHEDULER_CSR certificates"
fi

# The kubernetes-the-hard-way static IP address will be included in the list
# of subject alternative names for the Kubernetes API Server certificate. This
# will ensure the certificate can be validated by remote clients.

GENCERTS=
if [ ! -f "$API_SERVER_CSR" ]; then
    echo "----> Generating $API_SERVER_CSR"
    cat > ${API_SERVER_CSR} <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
},
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF
    GENCERTS=true
fi

if [ "$GENCERTS" = true ]; then
    echo "----> Generating $API_SERVER_CSR certificate"
    WORKERS=
    for ips in $WORKER_HOSTNAME_IP
    do
        WORKERS="$WORKERS,$(echo $ips | cut -d ',' -f 1)"
    done
    WORKERS=$(echo $WORKERS | sed 's/^.//')
    echo "  ADDING $WORKERS to API SERVER hostname cert"
    cfssl gencert \
        -ca=${CA_PATH}/ca.pem \
        -ca-key=${CA_PATH}/ca-key.pem \
        -config=${CA_CONFIG} \
        -hostname=${WORKERS},${SERVICE_GW},${INTERNAL_IP},${EXTERNAL_IP},127.0.0.1,kubernetes.default \
        -profile=${CA_PROFILE} \
        ${API_SERVER_CSR} | cfssljson -bare ${API_SERVER_PATH}/kubernetes > /dev/null
else
    echo "----> No work to do for $API_SERVER_CSR certificates"
fi

# The Kubernetes Controller Manager leverages a key pair to generate and
# sign service account tokens as describe in the managing service accounts documentation.
# https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/

GENCERTS=
if [ ! -f "$SERVICE_ACCOUNT_CSR" ]; then
    echo "----> Generating $SERVICE_ACCOUNT_CSR"
    cat > ${SERVICE_ACCOUNT_CSR} <<EOF
{
  "CN": "service-accounts",
  "key": {
    "algo": "rsa",
    "size": 2048
},
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF
    GENCERTS=true
fi

if [ "$GENCERTS" = true ]; then
    echo "----> Generating $SERVICE_ACCOUNT_CSR certificate"
    cfssl gencert \
        -ca=${CA_PATH}/ca.pem \
        -ca-key=${CA_PATH}/ca-key.pem \
        -config=${CA_CONFIG} \
        -profile=${CA_PROFILE} \
        ${SERVICE_ACCOUNT_CSR} | cfssljson -bare ${SERVICE_ACCOUNT_PATH}/service-account > /dev/null
else
    echo "----> No work to do for $SERVICE_ACCOUNT_CSR certificates"
fi

# ------------------------------- KUBE CONFIG FILES START -------------------------------
echo "BUILDING admin.kubeconfig"
kubectl config set-cluster ${NETWORK_NAME} \
    --certificate-authority=${CA_PATH}/ca.pem \
    --embed-certs=true \
    --server=https://${EXTERNAL_IP}:6443 \
    --kubeconfig=${ADMIN_KUBE_CONFIG_PATH}/admin.kubeconfig > /dev/null

kubectl config set-credentials admin \
    --client-certificate=${ADMIN_PATH}/admin.pem \
    --client-key=${ADMIN_PATH}/admin-key.pem \
    --embed-certs=true \
    --kubeconfig=${ADMIN_KUBE_CONFIG_PATH}/admin.kubeconfig > /dev/null

kubectl config set-context ${KUBE_CFG_CONTEXT} \
    --cluster=${NETWORK_NAME} \
    --user=admin \
    --kubeconfig=${ADMIN_KUBE_CONFIG_PATH}/admin.kubeconfig > /dev/null

kubectl config use-context ${KUBE_CFG_CONTEXT} \
    --kubeconfig=${ADMIN_KUBE_CONFIG_PATH}/admin.kubeconfig > /dev/null


echo "BUILDING controller-manager.kubeconfig"
kubectl config set-cluster ${NETWORK_NAME} \
    --certificate-authority=${CA_PATH}/ca.pem \
    --embed-certs=true \
    --server=https://${EXTERNAL_IP}:6443 \
    --kubeconfig=${CTRLR_MGR_KUBE_CONFIG_PATH}/kube-controller-manager.kubeconfig > /dev/null

kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=${CTRLR_MGR_PATH}/kube-controller-manager.pem \
    --client-key=${CTRLR_MGR_PATH}/kube-controller-manager-key.pem \
    --embed-certs=true \
    --kubeconfig=${CTRLR_MGR_KUBE_CONFIG_PATH}/kube-controller-manager.kubeconfig > /dev/null

kubectl config set-context ${KUBE_CFG_CONTEXT} \
    --cluster=${NETWORK_NAME} \
    --user=system:kube-controller-manager \
    --kubeconfig=${CTRLR_MGR_KUBE_CONFIG_PATH}/kube-controller-manager.kubeconfig > /dev/null

kubectl config use-context ${KUBE_CFG_CONTEXT} \
    --kubeconfig=${CTRLR_MGR_KUBE_CONFIG_PATH}/kube-controller-manager.kubeconfig > /dev/null


echo "BUILDING kube-proxy.kubeconfig"
kubectl config set-cluster ${NETWORK_NAME} \
    --certificate-authority=${CA_PATH}/ca.pem \
    --embed-certs=true \
    --server=https://${EXTERNAL_IP}:6443 \
    --kubeconfig=${PROXY_KUBE_CONFIG_PATH}/kube-proxy.kubeconfig > /dev/null

kubectl config set-credentials system:kube-proxy \
    --client-certificate=${KUBE_PROXY_PATH}/kube-proxy.pem \
    --client-key=${KUBE_PROXY_PATH}/kube-proxy-key.pem \
    --embed-certs=true \
    --kubeconfig=${PROXY_KUBE_CONFIG_PATH}/kube-proxy.kubeconfig > /dev/null

kubectl config set-context ${KUBE_CFG_CONTEXT} \
    --cluster=${NETWORK_NAME} \
    --user=system:kube-proxy \
    --kubeconfig=${PROXY_KUBE_CONFIG_PATH}/kube-proxy.kubeconfig > /dev/null

kubectl config use-context ${KUBE_CFG_CONTEXT} \
    --kubeconfig=${PROXY_KUBE_CONFIG_PATH}/kube-proxy.kubeconfig > /dev/null


echo "BUILDING kube-scheduler.kubeconfig"
kubectl config set-cluster ${NETWORK_NAME} \
    --certificate-authority=${CA_PATH}/ca.pem \
    --embed-certs=true \
    --server=https://${EXTERNAL_IP}:6443 \
    --kubeconfig=${SCHEDULER_KUBE_CONFIG_PATH}/kube-scheduler.kubeconfig > /dev/null

kubectl config set-credentials system:kube-scheduler \
    --client-certificate=${SCHEDULER_PATH}/kube-scheduler.pem \
    --client-key=${SCHEDULER_PATH}/kube-scheduler-key.pem \
    --embed-certs=true \
    --kubeconfig=${SCHEDULER_KUBE_CONFIG_PATH}/kube-scheduler.kubeconfig > /dev/null

kubectl config set-context ${KUBE_CFG_CONTEXT} \
    --cluster=${NETWORK_NAME} \
    --user=system:kube-scheduler \
    --kubeconfig=${SCHEDULER_KUBE_CONFIG_PATH}/kube-scheduler.kubeconfig > /dev/null

kubectl config use-context ${KUBE_CFG_CONTEXT} \
    --kubeconfig=${SCHEDULER_KUBE_CONFIG_PATH}/kube-scheduler.kubeconfig > /dev/null


sudo mkdir -p /etc/etcd /var/lib/etcd
sudo cp $CA_PATH/ca.pem  \
            $API_SERVER_PATH/kubernetes-key.pem \
            $API_SERVER_PATH/kubernetes.pem /etc/etcd/

echo " ************ External IP: ${EXTERNAL_IP}, etcd name: ${ETCD_NAME} ************ "
echo " ************ Creating etcd systemd unit file ************ "
cat <<EOF | sudo tee /etc/systemd/system/etcd.service > /dev/null
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/local/bin/etcd \\
  --name ${HOSTNAME} \\
  --initial-advertise-peer-urls https://${EXTERNAL_IP}:2380 \\
  --listen-peer-urls https://${EXTERNAL_IP}:2380 \\
  --listen-client-urls https://${EXTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${EXTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster ${HOSTNAME}=https://${EXTERNAL_IP}:2380 \\
  --initial-cluster-state new \\
  --cert-file=/etc/etcd/kubernetes.pem \\
  --key-file=/etc/etcd/kubernetes-key.pem \\
  --peer-cert-file=/etc/etcd/kubernetes.pem \\
  --peer-key-file=/etc/etcd/kubernetes-key.pem \\
  --trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo " ************ starting etcd ************ "
sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl start etcd

sleep 5

echo " ************ Printing etcd member list ************ "
sudo ETCDCTL_API=3 etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/kubernetes.pem \
  --key=/etc/etcd/kubernetes-key.pem

sudo mkdir -p /var/lib/kubernetes/
sudo cp $CA_PATH/ca.pem $CA_PATH/ca-key.pem \
    $API_SERVER_PATH/kubernetes-key.pem $API_SERVER_PATH/kubernetes.pem \
        $SERVICE_ACCOUNT_PATH/service-account-key.pem $SERVICE_ACCOUNT_PATH/service-account.pem \
        /var/lib/kubernetes/


echo " ************ Create kube-apiserver systemd unit file ************ "
cat <<EOF | sudo tee /etc/systemd/system/kube-apiserver.service > /dev/null
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \\
  --advertise-address=${EXTERNAL_IP} \\
  --apiserver-count=1 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit.log \\
  --enable-swagger-ui=true \\
  --allow-privileged=true \\
  --authorization-mode=Node,RBAC \\
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
  --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
  --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
  --kubelet-https=true \\
  --service-account-key-file=/var/lib/kubernetes/service-account.pem \\
  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/var/lib/kubernetes/ca.pem \\
  --etcd-servers=https://${EXTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --etcd-cafile=/var/lib/kubernetes/ca.pem \\
  --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
  --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
  --event-ttl=1h \\
  --runtime-config=api/all \\
  --service-cluster-ip-range=${SERVICE_IP_CIDR} \\
  --service-node-port-range=30000-32767 \\
  --admission-control=ServiceAccount \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo cp ${CTRLR_MGR_KUBE_CONFIG_PATH}/kube-controller-manager.kubeconfig /var/lib/kubernetes/

echo " ************ Creating kube-controller-manager systemd unit file ************ "
cat <<EOF | sudo tee /etc/systemd/system/kube-controller-manager.service > /dev/null
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \\
  --address=0.0.0.0 \\
  --master=https://127.0.0.1:6443\\
  --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \\
  --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \\
  --root-ca-file=/var/lib/kubernetes/ca.pem \\
  --service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \\
  --use-service-account-credentials=true \\
  --cluster-cidr=${CLUSTER_CIDR} \\
  --cluster-name=${NETWORK_NAME} \\
  --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --leader-elect=true \\
  --service-cluster-ip-range=${SERVICE_IP_CIDR} \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo cp ${SCHEDULER_KUBE_CONFIG_PATH}/kube-scheduler.kubeconfig /var/lib/kubernetes/

echo " ************ Creating kube-scheduler yaml config file ************ "
cat <<EOF | sudo tee /etc/kubernetes/config/kube-scheduler.yaml > /dev/null
apiVersion: kubescheduler.config.k8s.io/v1alpha1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
leaderElection:
  leaderElect: true
EOF

echo " ************ Creating kube-scheduler systemd unit file ************ "
cat <<EOF | sudo tee /etc/systemd/system/kube-scheduler.service > /dev/null
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \\
  --master=https://127.0.0.1:6443 \\
  --config=/etc/kubernetes/config/kube-scheduler.yaml \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

{
    echo " ************ Start controller services: kube-apiserver kube-controller-manager kube-scheduler ************ "
    sudo systemctl daemon-reload
    sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler
    sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler
}

# Allow up to 10 seconds for the Kubernetes API Server to fully initialize.
echo " ************ Allow 10 seconds for Kubernetes API server to initialize ************ "
sleep 10

echo " ************ Check kubernetes component status ************ "
kubectl get componentstatuses --kubeconfig ${ADMIN_KUBE_CONFIG_PATH}/admin.kubeconfig

echo " ************ Check kube-apiserver version over HTTPS ************ "
curl --cacert $CA_PATH/ca.pem https://${EXTERNAL_IP}:6443/version

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
sudo skaffold config set default-repo bekerr1

# experimental. This seems to be needed...
sudo iptables -P FORWARD ACCEPT

