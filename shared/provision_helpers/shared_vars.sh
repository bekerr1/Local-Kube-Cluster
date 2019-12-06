#!/bin/bash

# Create custom VPC network
NETWORK_NAME=kubernetes-the-hard-way
CLUSTER_IPS=/home/vagrant/shared/provision_helpers/node_external_ips
KUBE_CFG_CONTEXT=default

# VM External IP controller nodes are in range 10.200.10.10/24
# VM Internal IP controller nodes are in range 10.200.0.10/24
# VM External IP worker nodes are in range 10.200.10.20/24
# VM Internal IP worker nodes are in range 10.200.0.20/24
EXTERNAL_IP=
INTERNAL_IP=
DNS_POD_IP=192.168.50.250
SERVICE_GW=192.168.50.1
CLUSTER_CIDR=192.168.10.0/16
POD_CIDR=192.168.25.0/24
SERVICE_IP_CIDR=192.168.50.0/24

# CA
CA_PROFILE=kubernetes
CA_SHARED=/home/vagrant/shared/pki
CA_PATH=$CA_SHARED/ca
CA=$CA_PATH/ca.pem
CA_KEY=$CA_PATH/ca-key.pem
CA_CONFIG=$CA_PATH/ca-config.json
CA_CSR=$CA_PATH/ca-csr.json

# Admin
ADMIN_PATH=$CA_SHARED/admin
ADMIN_CA=$ADMIN_PATH/admin.pem
ADMIN_KEY=$ADMIN_PATH/admin-key.pem
ADMIN_CSR=$ADMIN_PATH/admin-csr.json
ADMIN_KUBE_CONFIG_PATH=/home/vagrant/admin-kubeconfig

# Kube proxy
KUBE_PROXY_PATH=${CA_SHARED}/kube-proxy
KUBE_PROXY_CSR=${KUBE_PROXY_PATH}/kube-proxy-csr.json

