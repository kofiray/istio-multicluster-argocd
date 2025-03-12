# Istio Multi-Cluster with ArgoCD and Azure Front Door

This repository contains the configuration for managing Istio across multiple AKS clusters using ArgoCD and Azure Front Door for traffic distribution.

## Prerequisites

- Azure CLI installed and configured
- Terraform v1.0.0 or later
- kubectl installed
- Helm v3.0.0 or later
- Azure subscription with necessary permissions

## Repository Structure

```
istio-multicluster-argocd/
├── applicationsets/
│   ├── istio-base.yaml
│   ├── istiod.yaml
│   └── gateway.yaml
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── aks-clusters.tf
│   └── terraform.tfvars
├── .gitignore
└── README.md
```

## Setup Instructions

1. Clone the repository:
   ```bash
   git clone https://github.com/kofiray/istio-multicluster-argocd.git
   cd istio-multicluster-argocd
   ```

2. Configure Terraform:
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   ```
   Edit `terraform.tfvars` with your specific values.

3. Initialize and apply Terraform to create AKS clusters and install ArgoCD:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```
   This will:
   - Create two AKS clusters (UK South and UK West)
   - Install ArgoCD in both clusters using Helm
   - Configure Azure Front Door
   - Set up required networking and security configurations

4. Access ArgoCD UI:
   ```bash
   # Get ArgoCD admin password for UK South cluster
   kubectl --kubeconfig ~/.kube/config-uksouth -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

   # Get ArgoCD admin password for UK West cluster
   kubectl --kubeconfig ~/.kube/config-ukwest -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

   # Get ArgoCD LoadBalancer IP for UK South
   kubectl --kubeconfig ~/.kube/config-uksouth -n argocd get svc argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

   # Get ArgoCD LoadBalancer IP for UK West
   kubectl --kubeconfig ~/.kube/config-ukwest -n argocd get svc argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
   ```
   Access the ArgoCD UI at `https://<LOAD_BALANCER_IP>` with username `admin` and the password obtained above.

5. Apply ArgoCD ApplicationSets for Istio components:
   ```bash
   kubectl --kubeconfig ~/.kube/config-uksouth apply -f applicationsets/istio-base.yaml
   kubectl --kubeconfig ~/.kube/config-uksouth apply -f applicationsets/istiod.yaml
   kubectl --kubeconfig ~/.kube/config-uksouth apply -f applicationsets/gateway.yaml
   ```

## Configuration Details

### AKS Clusters
- Two AKS clusters are created in UK South and UK West regions
- Each cluster has:
  - Default node pool for general workloads
  - Dedicated node pool for Istio Gateway with appropriate taints/tolerations
  - Managed identity for authentication
  - Network plugin: Azure CNI
  - Kubernetes version: 1.27.3 (configurable)

### Azure Front Door
- Standard SKU Front Door profile
- Origin groups configured for both clusters
- Health probes and load balancing rules
- Custom routing rules for traffic distribution

### Istio Configuration
- Base Istio installation
- Istiod control plane
- Ingress gateways with Azure Front Door integration

### ArgoCD Installation
- Installed via Helm chart (version 5.51.6)
- High Availability (HA) mode enabled
- ApplicationSet controller enabled
- LoadBalancer service type for UI access
- Insecure mode enabled (consider configuring TLS in production)

## Maintenance

### Updating Kubernetes Version
1. Update `