#!/bin/bash

set +e

read -p "Do you want to install or upgrade helm repo? (Type in/up)" anw

if [ $anw ==  in ]
   then
     printf "\033[33mAdding Helm repo\033[0m\n\n"    

   declare -A repos=(
     [traefik]="https://traefik.github.io/charts"
     [jetstack]="https://charts.jetstack.io"
     [authentik]="https://charts.goauthentik.io"
     [argo]="https://argoproj.github.io/argo-helm"
     [keel]="https://charts.keel.sh"
)

     for repo in "${!repos[@]}"; do
       helm repo add "$repo" "${repos[$repo]}"
     done

     printf "\033[33mUpdating Helm repo\033[0m\n\n"
     helm repo update

     printf "\033[33mCreating required namespaces\033[0m\n\n"
     for namespace in traefik cert-manager argocd; do kubectl create namespace $namespace; done

   declare -A installs=(
    [traefik]="traefik/traefik $HOME/kubernetes/traefik/values.yaml traefik"
    [cert-manager]="jetstack/cert-manager $HOME/kubernetes/certmanager/values.yaml cert-manager"
    [authentik]="authentik/authentik $HOME/kubernetes/authentik/values.yaml authentik"
    [argocd]="argo/argo-cd $HOME/kubernetes/argocd/values.yaml argocd"
    [keel]="keel/keel $HOME/kubernetes/keel/keel-values.yaml kube-system"
)

     for app in "${!installs[@]}"; do
       IFS=' ' read -r chart values namespace <<< "${installs[$app]}"
       printf "\033[33mInstalling $app...\033[0m\n\n"
       helm install --namespace="$namespace" "$app" "$chart" -f "$values"
     done

     printf "\033[32mInstall Completed\033[0m\n\n"

elif [ $anw == up ]
   then
     printf "\033[33Updating helm repo\033[0m\n\n"
     helm repo update

   declare -A upgrades=(
    [traefik]="traefik/traefik $HOME/kubernetes/traefik/values.yaml traefik"
    [cert-manager]="jetstack/cert-manager $HOME/kubernetes/certmanager/values.yaml cert-manager"
    [authentik]="authentik/authentik $HOME/kubernetes/authentik/values.yaml authentik"
    [argocd]="argo/argo-cd $HOME/kubernetes/argocd/values.yaml argocd"
    [keel]="keel/keel $HOME/kubernetes/keel/keel-values.yaml kube-system"
)

     for app in "${!upgrades[@]}"; do
       IFS=' ' read -r chart values namespace <<< "${upgrades[$app]}"
       printf "\033[33mUpgrading $app...\033[0m\n\n"
       helm upgrade --namespace="$namespace" "$app" "$chart" -f "$values"
     done

else
	echo "Please type in (install) or up (upgrade)"	
fi

