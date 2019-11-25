#!/bin/bash

# 1 - NETWORK_NAME
# 2 - CA
# 3 - API_SERVER_IP
# 4 - ADMIN_CA
# 5 - ADMIN_KEY

kubectl config set-cluster $1 \
    --certificate-authority=$2 \
    --embed-certs=true \
    --server=https://$3:6443

kubectl config set-credentials admin \
    --client-certificate=$4 \
    --client-key=$5

kubectl config set-context $1 \
    --cluster=$1 \
    --user=admin

kubectl config use-context $1
