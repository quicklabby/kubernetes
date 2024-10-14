#!/bin/bash

set +e

read -p "Do you want to install or upgrade helm repo? (Type in/up)" anw

if [ $anw ==  in ]
   then 
     echo "Adding helm repo"   	   
     helm repo add traefik https://traefik.github.io/charts
     helm repo add jetstack https://charts.jetstack.io
     helm repo add authentik https://charts.goauthentik.io
     helm repo add argo https://argoproj.github.io/argo-helm
     helm repo add keel https://charts.keel.sh 

     echo "Updating helm repo"
     helm repo update

     echo "Creating required namespaces"
     kubectl create namespace traefik
     kubectl create namespace cert-manager
     kubectl create namespace argocd

     echo "Installing required helm repo"
     kelm install --namespace=traefik traefik traefik/traefik -f ~/kubernetes/traefik/values.yaml #input the correct path of your value.yaml directory
     echo ""
     helm install cert-manager jetstack/cert-manager --namespace cert-manager -f ~/kubernetes/certmanager/values.yaml #input the correct path of your value.yaml directory
     echo ""
     helm install authentik authentik/authentik -f ~/kubernetes/authentik/values.yaml #input the correct path of your value.yaml directory
     echo ""
     helm install argocd argo/argo-cd  --namespace argocd -f ~/kubernetes/argocd/values.yaml #input the correct path of your value.yaml directory
     echo ""
     helm install keel --namespace=kube-system keel/keel -f ~/kubernetes/keel/keel-values.yaml #input the correct path of your value.yaml directory
     echo "Installation Completed"

elif [ $anw == up ]
   then
     echo "Updating helm repo"
     helm repo update

     echo "Upgrading helm repo"
     helm upgrade --namespace=traefik traefik traefik/traefik -f ~/kubernetes/traefik/values.yaml
     echo ""
     helm upgrade cert-manager jetstack/cert-manager --namespace cert-manager -f ~/kubernetes/certmanager/values.yaml #input the correct path of your value.yaml directory
     echo ""
     helm upgrade authentik authentik/authentik -f ~/kubernetes/authentik/values.yaml #input the correct path of your value.yaml directory
     echo ""
     helm upgrade argocd argo/argo-cd  --namespace argocd -f ~/kubernetes/argocd/values.yaml #input the correct path of your value.yaml directory
     echo ""
     helm upgrade keel --namespace=kube-system keel/keel -f ~/kubernetes/keel/keel-values.yaml #input the correct path of your value.yaml directory
     echo "Upgrade Completed"

else
	echo "Please type in (install) or up (upgrade)"	
fi
