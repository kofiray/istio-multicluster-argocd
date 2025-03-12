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

2. Configure Terraform:
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   ```
   Edit `terraform.tfvars` with your specific values for:
   - AKS cluster configurations (resource group, locations, node sizes)
   - Azure Front Door settings
   - ArgoCD Helm chart version
   - Resource tags

3. Initialize and apply Terraform:
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

## Maintenance

### Updating Kubernetes Version
1. Update `kubernetes_version` in `terraform.tfvars`
2. Run `terraform plan` and `terraform apply`
3. Verify cluster health after upgrade

### Updating Istio Version
1. Update `targetRevision` in `applicationsets/gateway.yaml`
2. Commit and push changes
3. ArgoCD will automatically sync the new version

### Updating ArgoCD Version
1. Update `argocd_helm_chart_version` in `terraform.tfvars`
2. Run `terraform plan` and `terraform apply`

### Monitoring Health
1. Check Azure Front Door metrics in Azure Portal
2. Monitor Istio Gateway pods:
   ```bash
   kubectl --kubeconfig ~/.kube/config-uksouth -n istio-system get pods
   kubectl --kubeconfig ~/.kube/config-ukwest -n istio-system get pods
   ```
3. Verify ArgoCD applications status in UI or CLI:
   ```bash
   kubectl --kubeconfig ~/.kube/config-uksouth -n argocd get applications
   ```

## Security Considerations

1. ArgoCD is exposed via LoadBalancer - consider implementing ingress with TLS
2. Update ArgoCD admin password after initial setup
3. Review and adjust RBAC permissions as needed
4. Consider enabling network policies
5. Regularly update all components to latest stable versions

## Troubleshooting

### Common Issues

1. ArgoCD sync failures:
   - Check application logs
   - Verify cluster credentials
   - Check network connectivity

2. Traffic distribution issues:
   - Verify Azure Front Door health probe status
   - Check Istio Gateway pods are running
   - Verify service endpoints are correctly configured

3. Node pool issues:
   - Verify node labels and taints
   - Check resource quotas
   - Monitor node health

For more detailed troubleshooting, check the logs:
```bash
# Istio Gateway logs
kubectl --kubeconfig ~/.kube/config-uksouth -n istio-system logs -l app=istio-ingressgateway

# ArgoCD logs
kubectl --kubeconfig ~/.kube/config-uksouth -n argocd logs -l app.kubernetes.io/name=argocd-server
```