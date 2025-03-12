# Istio Multi-Cluster with Azure Front Door

This repository contains the configuration for managing Istio across multiple clusters using ArgoCD ApplicationSets and Azure Front Door for traffic distribution.

## Architecture

- Two Kubernetes clusters (UK South and UK West)
- Istio service mesh deployed on both clusters
- Azure Front Door for traffic distribution and load balancing
- ArgoCD for GitOps-based deployment and management

## Directory Structure

```
.
├── applicationsets/
│   ├── istio-base.yaml
│   ├── istiod.yaml
│   └── gateway.yaml
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── terraform.tfvars
└── README.md
```

## Prerequisites

1. Two Kubernetes clusters (UK South and UK West)
2. ArgoCD installed on both clusters
3. Azure subscription with permissions to create Front Door resources
4. Kubeconfig files for both clusters

## Setup Instructions

1. Update Terraform Variables:
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. Initialize and Apply Terraform:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. Apply ArgoCD ApplicationSets:
   ```bash
   kubectl apply -f applicationsets/istio-base.yaml
   kubectl apply -f applicationsets/istiod.yaml
   kubectl apply -f applicationsets/gateway.yaml
   ```

4. Verify Installation:
   ```bash
   # Check Istio components in UK South
   kubectl --context=uksouth -n istio-system get pods

   # Check Istio components in UK West
   kubectl --context=ukwest -n istio-system get pods
   ```

## Traffic Distribution

Azure Front Door is configured to distribute traffic between the UK South and UK West clusters with:
- Equal weight distribution (50/50)
- Health probes every 30 seconds
- Session affinity enabled
- Automatic failover if a cluster becomes unhealthy

## Monitoring

Monitor the setup using:
1. Azure Front Door metrics in Azure Portal
2. Istio's built-in monitoring with Prometheus and Grafana
3. ArgoCD dashboard for deployment status

## Troubleshooting

1. Check ArgoCD application status:
   ```bash
   kubectl get applications -n argocd
   ```

2. Check Istio pods:
   ```bash
   kubectl get pods -n istio-system
   ```

3. Check Azure Front Door health probe status in Azure Portal

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

MIT License 