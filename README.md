# Istio Multi-Cluster with ArgoCD and Azure Front Door

This repository contains the configuration for managing Istio across multiple AKS clusters using ArgoCD and Azure Front Door for traffic distribution.

## Prerequisites

- Azure CLI installed and configured
- Terraform v1.0.0 or later
- kubectl installed
- Helm v3.0.0 or later
- Azure subscription with necessary permissions
- Git client

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

2. Configure Azure Key Vault:
   ```bash
   # First time setup: Store your PAT token in Azure Key Vault
   az group create --name istio-secrets-rg --location uksouth
   az keyvault create --name istio-multicluster-kv --resource-group istio-secrets-rg --location uksouth
   az keyvault secret set --vault-name istio-multicluster-kv --name "git-pat-token" --value "YOUR-PAT-TOKEN"
   ```

3. Configure Terraform:
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   ```
   Edit `terraform.tfvars` with your specific values for:
   - AKS cluster configurations (resource group, locations, node sizes)
   - Azure Front Door settings
   - ArgoCD Helm chart version
   - Git repository URL
   - Resource tags

4. Initialize and apply Terraform:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```
   This will:
   - Create two AKS clusters (UK South and UK West)
   - Create dedicated node pools for Istio Gateway
   - Install ArgoCD in both clusters using Helm
   - Configure Azure Front Door
   - Set up required networking and security configurations
   - Configure ArgoCD with repository and project settings (using PAT from Key Vault)
   - Apply Istio ApplicationSets automatically

5. Access ArgoCD UI:
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

6. Apply ArgoCD ApplicationSets for Istio components:
   ```