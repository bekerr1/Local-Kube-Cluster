#!/bin/bash

# Controller manager
CTRLR_MGR_PATH=$CA_SHARED/controller-manager
CTRLR_MGR_CSR=$CTRLR_MGR_PATH/kube-controller-manager-csr.json
CTRLR_MGR_KUBE_CONFIG_PATH=/home/vagrant/ctrlr-mgr-kubeconfig

# Scheduler
SCHEDULER_PATH=$CA_SHARED/scheduler
SCHEDULER_CSR=$SCHEDULER_PATH/kube-scheduler-csr.json
SCHEDULER_KUBE_CONFIG_PATH=/home/vagrant/scheduler-kubeconfig

# API Server
API_SERVER_PATH=$CA_SHARED/api-server
API_SERVER_CSR=$API_SERVER_PATH/kubernetes-csr.json

# Encryption config and key
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
ENCRYPTION_CONFIG=/home/vagrant/config/encryption-config.yaml
ENCRYPTION_FILE=encryption-config.yaml

# Service Account
SERVICE_ACCOUNT_PATH=$CA_SHARED/service-account
SERVICE_ACCOUNT_CSR=$SERVICE_ACCOUNT_PATH/service-account-csr.jsonS

