#!/bin/bash

# Worker CA
WORKER_PATH=$CA_SHARED/worker
WORKER_CSR=$WORKER_PATH/${HOSTNAME}-csr.json
WORKER_CA=$WORKER_PATH/${HOSTNAME}.pem
WORKER_KEY=$WORKER_PATH/${HOSTNAME}-key.pem
WORKER_KUBE_CONFIG_PATH=/home/vagrant/worker-kubeconfig

PROXY_KUBE_CONFIG_PATH=/home/vagrant/proxy-kubeconfig
