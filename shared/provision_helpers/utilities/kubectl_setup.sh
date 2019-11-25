#!/bin/bash

function setup_kubectl() {
    kubectl config set-cluster kubernetes-the-hard-way \
        --certificate-authority=shared/pki/ca/ca.pem \
        --embed-certs=true \
        --server=https://10.200.10.10:6443

    kubectl config set-credentials admin \
        --client-certificate=shared/pki/admin/admin.pem \
        --client-key=shared/pki/admin/admin-key.pem

    kubectl config set-context kubernetes-the-hard-way \
        --cluster=kubernetes-the-hard-way \
        --user=admin

    kubectl config use-context kubernetes-the-hard-way
}
setup_kubectl
