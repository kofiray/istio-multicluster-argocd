# Architecture Documentation

This directory contains the architecture diagram for the Istio Multi-Cluster setup with Azure Front Door and ArgoCD.

## Prerequisites

- Python 3.7 or later
- Graphviz (required for diagram generation)

### Installing Graphviz

#### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install graphviz
```

#### Fedora
```bash
sudo dnf install graphviz
```

#### macOS
```bash
brew install graphviz
```

## Setup

1. Create a Python virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install the required Python packages:
```bash
pip install -r requirements.txt
```

## Generating the Diagram

To generate the architecture diagram:

```bash
python architecture.py
```

This will create a PNG file named `istio_multi_cluster_with_azure_front_door_and_argocd.png` in the current directory.

## Architecture Overview

The diagram shows:

1. **Azure Front Door**
   - Load balances traffic between UK South and UK West regions
   - Provides global routing and failover

2. **Azure Key Vault**
   - Stores GitHub PAT token securely
   - Used by ArgoCD for repository authentication

3. **UK South and UK West Regions**
   Each region contains:
   - AKS Cluster
   - ArgoCD installation
   - Istio control plane (Istiod)
   - Istio Gateway
   - Application workloads

4. **GitOps Flow**
   - GitHub repository contains Istio and application configurations
   - ArgoCD continuously syncs configurations to both clusters
   - Helm manages the deployment of components

## Diagram Components

- Blue boxes represent Azure services
- White boxes represent Kubernetes resources
- Arrows show the flow of traffic and control
- Clusters (dotted boxes) show logical grouping of components 