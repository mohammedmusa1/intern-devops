#!/bin/bash
set -ex

# Redirect stdout and stderr to a log file
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting deployment..."

# 1. Update and install dependencies
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y curl wget git jq apt-transport-https ca-certificates software-properties-common

# 2. Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io
usermod -aG docker ubuntu

# 3. Install K3s (lightweight, robust, no TLS issues)
curl -sfL https://get.k3s.io | sh -s - server --write-kubeconfig-mode 644 --disable traefik

# Wait for K3s to be ready
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
until kubectl get nodes | grep -w "Ready"; do
  echo "Waiting for k3s node to be ready..."
  sleep 5
done

# Allow ubuntu user to use kubectl
mkdir -p /home/ubuntu/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
chown -R ubuntu:ubuntu /home/ubuntu/.kube
export KUBECONFIG=/home/ubuntu/.kube/config

# 4. Install Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
bash get_helm.sh

# 5. Create directories and config files
mkdir -p /opt/devops/{jenkins,argocd,monitoring,helm,k8s}

cat << 'EOF' > /opt/devops/jenkins/values.yaml
${jenkins_values}
EOF

cat << 'EOF' > /opt/devops/argocd/values.yaml
${argocd_values}
EOF

cat << 'EOF' > /opt/devops/argocd/application.yaml
${argocd_application}
EOF

cat << 'EOF' > /opt/devops/monitoring/prometheus-values.yaml
${prometheus_values}
EOF

cat << 'EOF' > /opt/devops/monitoring/grafana-values.yaml
${grafana_values}
EOF

cat << 'EOF' > /opt/devops/helm/ingress-nginx-values.yaml
${ingress_values}
EOF

# 6. Create namespaces
kubectl create namespace jenkins || true
kubectl create namespace argocd || true
kubectl create namespace monitoring || true
kubectl create namespace ingress-nginx || true

# 7. Add Helm Repos
helm repo add jenkins https://charts.jenkins.io
helm repo add argo https://argoproj.github.io/argo-helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# 8. Install Nginx Ingress
echo "Installing Ingress NGINX..."
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  -f /opt/devops/helm/ingress-nginx-values.yaml \
  --wait --timeout 10m || echo "Nginx Ingress failed to install"

# 9. Install Jenkins
echo "Installing Jenkins..."
helm upgrade --install jenkins jenkins/jenkins \
  --namespace jenkins \
  -f /opt/devops/jenkins/values.yaml \
  --wait --timeout 15m || echo "Jenkins failed to install"

# 10. Install ArgoCD
echo "Installing ArgoCD..."
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  -f /opt/devops/argocd/values.yaml \
  --wait --timeout 10m || echo "ArgoCD failed to install"

# 11. Install Prometheus
echo "Installing Prometheus..."
helm upgrade --install prometheus prometheus-community/prometheus \
  --namespace monitoring \
  -f /opt/devops/monitoring/prometheus-values.yaml \
  --wait --timeout 10m || echo "Prometheus failed to install"

# 12. Install Grafana
echo "Installing Grafana..."
helm upgrade --install grafana grafana/grafana \
  --namespace monitoring \
  -f /opt/devops/monitoring/grafana-values.yaml \
  --wait --timeout 10m || echo "Grafana failed to install"

# 13. Apply ArgoCD Application
echo "Waiting for ArgoCD CRDs to be established..."
until kubectl get crd applications.argoproj.io; do
  sleep 5
done

echo "Applying ArgoCD Application (with retries for webhook readiness)..."
for i in {1..10}; do
  kubectl apply -f /opt/devops/argocd/application.yaml && break || sleep 10
done

echo "Deployment complete!"

