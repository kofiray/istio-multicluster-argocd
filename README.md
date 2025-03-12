# Istio Multi-Cluster with ArgoCD and Azure Front Door

This repository contains the configuration for managing Istio across multiple AKS clusters using ArgoCD and Azure Front Door for traffic distribution.

## Prerequisites

- Azure CLI installed and configured
- Terraform v1.0.0 or later
- kubectl installed
- ArgoCD installed in your clusters
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

3. Initialize and apply Terraform to create AKS clusters and Front Door:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```
   This will create:
   - Two AKS clusters (UK South and UK West)
   - Azure Front Door profile
   - Required networking and security configurations

4. Get kubeconfig for both clusters:
   ```bash
   az aks get-credentials --resource-group aks-istio-rg --name aks-uksouth --file ~/.kube/config-uksouth
   az aks get-credentials --resource-group aks-istio-rg --name aks-ukwest --file ~/.kube/config-ukwest
   ```

5. Install ArgoCD in both clusters:
   ```bash
   kubectl --kubeconfig ~/.kube/config-uksouth create namespace argocd
   kubectl --kubeconfig ~/.kube/config-uksouth apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   
   kubectl --kubeconfig ~/.kube/config-ukwest create namespace argocd
   kubectl --kubeconfig ~/.kube/config-ukwest apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```

6. Apply ArgoCD ApplicationSets for Istio components:
   ```bash
   kubectl --kubeconfig ~/.kube/config-uksouth apply -f applicationsets/istio-base.yaml
   kubectl --kubeconfig ~/.kube/config-uksouth apply -f applicationsets/istiod.yaml
   kubectl --kubeconfig ~/.kube/config-uksouth apply -f applicationsets/gateway.yaml
   ```

7. Verify the setup:
   ```bash
   # Check Istio pods in both clusters
   kubectl --kubeconfig ~/.kube/config-uksouth get pods -n istio-system
   kubectl --kubeconfig ~/.kube/config-ukwest get pods -n istio-system
   
   # Check Front Door endpoint
   az network front-door endpoint show \
     --resource-group istio-frontdoor-rg \
     --profile-name istio-frontdoor \
     --endpoint-name istio-app
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

## Maintenance

### Updating Kubernetes Version
1. Update `kubernetes_version` in terraform.tfvars
2. Run `terraform plan` and `terraform apply`

### Adding New Clusters
1. Add new cluster configuration in aks-clusters.tf
2. Add corresponding Front Door origin in main.tf
3. Update ApplicationSets to include new cluster

## Troubleshooting

1. Check cluster health:
   ```bash
   az aks show -g aks-istio-rg -n aks-uksouth --query 'provisioningState'
   az aks show -g aks-istio-rg -n aks-ukwest --query 'provisioningState'
   ```

2. Verify Istio installation:
   ```bash
   istioctl verify-install --kubeconfig ~/.kube/config-uksouth
   istioctl verify-install --kubeconfig ~/.kube/config-ukwest
   ```

3. Check Front Door routing:
   ```bash
   az network front-door route show \
     --resource-group istio-frontdoor-rg \
     --profile-name istio-frontdoor \
     --name istio-route
   ```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

MIT License 