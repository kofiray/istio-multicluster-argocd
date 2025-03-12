from diagrams import Cluster, Diagram, Edge
from diagrams.azure.network import CDNProfiles, LoadBalancers
from diagrams.azure.compute import KubernetesServices
from diagrams.azure.security import KeyVaults
from diagrams.k8s.ecosystem import Helm
from diagrams.k8s.group import NS
from diagrams.onprem.gitops import ArgoCD
from diagrams.onprem.network import Istio
from diagrams.programming.framework import React
from diagrams.onprem.vcs import Github

with Diagram("Istio Multi-Cluster with Azure Front Door and ArgoCD", show=True, direction="TB"):
    # Azure Front Door
    afd = CDNProfiles("Azure Front Door")
    
    # Azure Key Vault
    kv = KeyVaults("Key Vault\n(PAT Token)")
    
    # GitHub Repository
    github = Github("Git Repository\n(Istio & App Config)")
    
    # UK South Region
    with Cluster("Azure Region - UK South"):
        # Load Balancer for UK South
        lb_south = LoadBalancers("Load Balancer")
        
        # AKS Cluster UK South
        with Cluster("AKS Cluster - UK South"):
            aks_south = KubernetesServices("AKS UK South")
            
            # ArgoCD in UK South
            with Cluster("ArgoCD Namespace"):
                argocd_south = ArgoCD("ArgoCD")
                helm_south = Helm("Helm")
            
            # Istio in UK South
            with Cluster("Istio System Namespace"):
                istio_south = Istio("Istio Gateway")
                istiod_south = Istio("Istiod")
            
            # Application in UK South
            with Cluster("Application Namespace"):
                app_south = React("Application")
    
    # UK West Region
    with Cluster("Azure Region - UK West"):
        # Load Balancer for UK West
        lb_west = LoadBalancers("Load Balancer")
        
        # AKS Cluster UK West
        with Cluster("AKS Cluster - UK West"):
            aks_west = KubernetesServices("AKS UK West")
            
            # ArgoCD in UK West
            with Cluster("ArgoCD Namespace"):
                argocd_west = ArgoCD("ArgoCD")
                helm_west = Helm("Helm")
            
            # Istio in UK West
            with Cluster("Istio System Namespace"):
                istio_west = Istio("Istio Gateway")
                istiod_west = Istio("Istiod")
            
            # Application in UK West
            with Cluster("Application Namespace"):
                app_west = React("Application")
    
    # Front Door Connections
    afd >> lb_south >> istio_south
    afd >> lb_west >> istio_west
    
    # Key Vault Connections
    kv >> argocd_south
    kv >> argocd_west
    
    # GitHub Connections
    github >> argocd_south
    github >> argocd_west
    
    # ArgoCD to Helm
    argocd_south >> helm_south
    argocd_west >> helm_west
    
    # Helm to Istio
    helm_south >> istio_south
    helm_south >> istiod_south
    helm_west >> istio_west
    helm_west >> istiod_west
    
    # Istio to Application
    istiod_south >> app_south
    istiod_west >> app_west
    istio_south >> app_south
    istio_west >> app_west 