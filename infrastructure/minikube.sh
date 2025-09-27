#!/bin/bash

# Nome do cluster
CLUSTER_NAME="test-cluster"

# Drive de virtualização (pode ser: docker, virtualbox, kvm2, hyperkit, etc.)
DRIVER="docker"

# Versão do Kubernetes
K8S_VERSION="v1.31.0"

# Recursos da VM
CPUS=4
MEMORY=8192
DISK_SIZE="30g"
NODES=3

# Habilitar addons (opcional)
ADDONS=("ingress" "metrics-server")

echo "🚀 Iniciando cluster Minikube: $CLUSTER_NAME"

minikube start \
  --profile=$CLUSTER_NAME \
  --driver=$DRIVER \
  --kubernetes-version=$K8S_VERSION 

# Habilitar addons
for addon in "${ADDONS[@]}"; do
  echo "🔧 Habilitando addon: $addon"
  minikube addons enable "$addon" --profile=$CLUSTER_NAME
done

echo "✅ Minikube provisionado com sucesso!"
