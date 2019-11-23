#!/bin/bash

# Create custom VPC network
NETWORK_NAME=kubernetes-the-hard-way

# Create subnet in VPC
EXTERNAL_IP=
INTERNAL_IP=
CLUSTER_CIDR=10.200.0.0/16
POD_CIDR=10.200.2.0/24
DNS_POD_IP=10.200.3.1
SERVICE_IP_CIDR=10.200.5.0/24
SERVICE_GW=10.200.5.1

# CA
CA_PROFILE=kubernetes
CA_SHARED=/home/vagrant/shared/pki
CA_PATH=$CA_SHARED/ca
CA_CONFIG=${CA_PATH}/ca-config.json
CA_KEY=${CA_PATH}/ca-key.pem
CA_CSR=${CA_PATH}/ca-csr.json

# Worker CA
WORKER_PATH=$CA_SHARED/worker
WORKER_CSR=$WORKER_PATH/${HOSTNAME}-csr.json
WORKER_CA=$WORKER_PATH/${HOSTNAME}.pem
WORKER_KEY=$WORKER_PATH/${HOSTNAME}-key.pem
WORKER_KUBE_CONFIG_PATH=/home/vagrant/worker-kubeconfig

# Admin
ADMIN_PATH=${CA_SHARED}/admin
ADMIN_CSR=${ADMIN_PATH}/admin-csr.json

# Controller manager
CTRLR_MGR_PATH=${CA_SHARED}/controller-manager
CTRLR_MGR_CSR=${CTRLR_MGR_PATH}/kube-controller-manager-csr.json

# Kube proxy
KUBE_PROXY_PATH=${CA_SHARED}/kube-proxy
KUBE_PROXY_CSR=${KUBE_PROXY_PATH}/kube-proxy-csr.json

# Scheduler
SCHEDULER_PATH=${CA_SHARED}/scheduler
SCHEDULER_CSR=${SCHEDULER_PATH}/kube-scheduler-csr.json

# API Server
API_SERVER_PATH=${CA_SHARED}/api-server
API_SERVER_CSR=${API_SERVER_PATH}/kubernetes-csr.json

# Service Account
SERVICE_ACCOUNT_PATH=${CA_SHARED}/service-account
SERVICE_ACCOUNT_CSR=${SERVICE_ACCOUNT_PATH}/service-account-csr.jsonS

PROXY_KUBE_CONFIG_PATH=/home/vagrant/proxy-kubeconfig
CTRLR_MGR_KUBE_CONFIG_PATH=/home/vagrant/ctrlr-mgr-kubeconfig
SCHEDULER_KUBE_CONFIG_PATH=/home/vagrant/scheduler-kubeconfig
ADMIN_KUBE_CONFIG_PATH=/home/vagrant/admin-kubeconfig

# Encryption config and key
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
ENCRYPTION_CONFIG=/home/vagrant/config/encryption-config.yaml
ENCRYPTION_FILE=encryption-config.yaml

# Kube proxy
KUBE_PROXY_PATH=/home/vagrant/shared/ca/kube-proxy
KUBE_PROXY_CSR=${KUBE_PROXY_PATH}/kube-proxy-csr.json
