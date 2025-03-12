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
│   ├── terraform.tfvars.example
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

   # Verify the secret was stored successfully
   az keyvault secret show --name git-pat-token --vault-name istio-multicluster-kv --query id
   ```

3. Configure Terraform:
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   ```
   
   Edit `terraform.tfvars` with your specific values. Here's a detailed explanation of each variable:

   ### AKS Cluster Configuration
   ```hcl
   aks_resource_group_name = "istio-aks-rg"     # Resource group for AKS clusters
   resource_group_name     = "istio-frontdoor-rg" # Resource group for Front Door
   kubernetes_version      = "1.27.3"            # Kubernetes version (optional)
   node_count             = 3                    # Number of nodes in default pool (optional)
   vm_size                = "Standard_D4s_v3"    # VM size for default pool (optional)
   gateway_vm_size        = "Standard_D4s_v3"    # VM size for gateway nodes (optional)
   gateway_node_count     = 2                    # Number of gateway nodes (optional)
   ```

   ### Kubeconfig Paths
   ```hcl
   uksouth_kubeconfig_path = "~/.kube/config-uksouth"  # Path to UK South kubeconfig
   ukwest_kubeconfig_path  = "~/.kube/config-ukwest"   # Path to UK West kubeconfig
   ```

   ### Azure Front Door Configuration
   ```hcl
   frontdoor_profile_name        = "istio-frontdoor"     # Front Door profile name
   frontdoor_endpoint_name      = "istio-endpoint"       # Endpoint name
   frontdoor_origin_group_name  = "istio-origin-group"   # Origin group name
   frontdoor_origin_name_uksouth = "uksouth-origin"      # UK South origin name
   frontdoor_origin_name_ukwest  = "ukwest-origin"       # UK West origin name
   frontdoor_route_name         = "istio-route"          # Route name
   app_hostname                 = "istio.example.com"     # Application hostname
   ```

   ### Git Repository Configuration
   ```hcl
   git_repository_url = "https://github.com/yourusername/istio-multicluster-argocd.git"
   git_username      = "your-github-username"
   ```

   ### ArgoCD Configuration
   ```hcl
   argocd_helm_version = "5.51.6"  # ArgoCD Helm chart version
   ```

   ### Resource Tags (Optional)
   ```hcl
   tags = {
     Environment = "Production"
     Project     = "Istio-MultiCluster"
     ManagedBy   = "Terraform"
   }
   ```

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

## Configuration Details

### AKS Clusters
- Two AKS clusters are created in UK South and UK West regions
- Each cluster has:
  - Default node pool for general workloads (Standard_D4s_v3, 3 nodes)
  - Dedicated node pool for Istio Gateway (Standard_D4s_v3, 2 nodes)
  - Node pool labels and taints for Istio Gateway (`purpose: istio-gateway`)
  - Managed identity for authentication
  - Network plugin: Azure CNI
  - Kubernetes version: 1.27.3 (configurable)

### Azure Front Door
- Standard SKU Front Door profile
- Origin groups configured for both clusters with:
  - Health probes every 30 seconds
  - Session affinity enabled
  - Equal weight distribution (50/50)
  - Proper HTTP/HTTPS port configuration
  - Health probe path: /healthz/ready

### Istio Configuration
- Base Istio installation via official Helm charts
- Istiod control plane
- Ingress gateways configured with:
  - LoadBalancer service type
  - HTTP (80/8080) and HTTPS (443/8443) ports
  - Resource requests: 500m CPU, 1Gi memory
  - Resource limits: 2000m CPU, 2Gi memory
  - 3 replicas for high availability
  - Node selector and tolerations for dedicated nodes

### ArgoCD Installation
- Installed via Helm chart (version 5.51.6)
- High Availability (HA) mode enabled
- ApplicationSet controller enabled
- LoadBalancer service type for UI access
- Automated sync policies with pruning and self-healing
- Namespace creation enabled
- Automated repository configuration:
  - Git repository connection automatically configured via Key Vault
  - Project "istio-system" created with appropriate permissions
  - ApplicationSets automatically applied
  - No manual repository setup required

### Azure Key Vault Integration
- Secure storage for Git PAT token
- Automatic retrieval during Terraform deployment
- No exposure of sensitive credentials in code or version control
- Managed access control through Azure RBAC
- Soft-delete and purge protection enabled

## Testing Traffic Distribution

To verify the traffic distribution between clusters:

```bash
# Run the automated test script
kubectl --kubeconfig ~/.kube/config-uksouth exec -it -n traffic-test traffic-test-runner -- /tmp/test-distribution.sh

# Or use the visual test command
for i in {1..100}; do 
  curl -s https://<FRONT_DOOR_ENDPOINT>/traffic-test | grep -o "UK [A-Z]*" || echo "Error";
  sleep 0.2;
done | sort | uniq -c
```

Expected results:
- Approximately 50/50 distribution between UK South and UK West
- Low error rate (< 1%)
- Consistent response times

## Maintenance

### Updating PAT Token
To update the PAT token:
```bash
az keyvault secret set --vault-name istio-multicluster-kv --name "git-pat-token" --value "NEW-PAT-TOKEN"
terraform apply  # To update ArgoCD configurations
```

### Updating Kubernetes Version
1. Update `kubernetes_version` in terraform.tfvars
2. Run `terraform apply` to upgrade the clusters

### Updating ArgoCD Version
1. Update `argocd_helm_version` in terraform.tfvars
2. Run `terraform apply` to upgrade ArgoCD

### Monitoring
- Check ArgoCD UI for sync status
- Monitor Azure Front Door metrics for traffic distribution
- Use Azure Monitor for cluster health
- Check Key Vault access logs for security monitoring

## Troubleshooting

### Common Issues

1. **ArgoCD Repository Connection**
   - Verify PAT token is correctly stored in Key Vault
   - Check ArgoCD logs for authentication errors
   - Ensure repository URL is correct

2. **Traffic Distribution**
   - Check Front Door health probe status
   - Verify Istio gateway pods are running
   - Check gateway service LoadBalancer status

3. **Cluster Access**
   - Verify kubeconfig paths are correct
   - Check AKS cluster status
   - Ensure proper RBAC permissions

### Getting Help
- Check ArgoCD logs: `kubectl logs -n argocd deploy/argocd-server`
- Check Istio logs: `kubectl logs -n istio-system deploy/istiod`
- Review Azure Front Door metrics in Azure Portal
- Open an issue in the repository for support