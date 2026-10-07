#!/bin/bash

set +e

YELLOW="\033[33m"; GREEN="\033[32m"; RED="\033[31m"; RESET="\033[0m"

# repo-name|url
repos=(
  "traefik|https://traefik.github.io/charts"
  "jetstack|https://charts.jetstack.io"
  "authentik|https://charts.goauthentik.io"
  "argo|https://argoproj.github.io/argo-helm"
  "keel|https://charts.keel.sh"
)

# Namespaces to create on install. public-apps must exist BEFORE traefik-external
# (the chart creates namespaced Roles in it).
namespaces=(traefik-internal traefik-external kube-system cert-manager argocd)

# release chart values-file namespace [extra helm flags]
# Order matters: the internal traefik release goes first because it owns the CRDs,
# so the external one is installed with --skip-crds.
releases=(
  "traefik traefik/traefik $HOME/kubernetes/traefik/values-internal.yaml traefik-internal"
  "traefik traefik/traefik $HOME/kubernetes/traefik/values-external.yaml traefik-external --skip-crds"
  "cert-manager jetstack/cert-manager $HOME/kubernetes/certmanager/values.yaml cert-manager"
  "authentik authentik/authentik $HOME/kubernetes/authentik/values.yaml authentik"
  "argocd argo/argo-cd $HOME/kubernetes/argocd/values.yaml argocd"
  "keel keel/keel $HOME/kubernetes/keel/keel-values.yaml kube-system"
)

run_releases() {
  local action="$1"   # install | upgrade
  local entry release chart values namespace extra
  for entry in "${releases[@]}"; do
    # shellcheck disable=SC2034
    read -r release chart values namespace extra <<< "$entry"
    printf "${YELLOW}%s %s (namespace: %s)...${RESET}\n\n" "$action" "$release" "$namespace"
    if [ "$action" = "install" ]; then
      # $extra is intentionally unquoted so it can hold flags (empty for most releases)
      # shellcheck disable=SC2086
      helm install --namespace="$namespace" "$release" "$chart" -f "$values" $extra
    else
      helm upgrade --namespace="$namespace" "$release" "$chart" -f "$values"
    fi
    if [ $? -ne 0 ]; then
      printf "${RED}%s failed for %s in %s${RESET}\n\n" "$action" "$release" "$namespace"
    fi
  done
}

read -rp "Do you want to install or upgrade helm releases? (Type in/up): " anw

case "$anw" in
  in)
    printf "${YELLOW}Adding Helm repos${RESET}\n\n"
    for entry in "${repos[@]}"; do
      helm repo add "${entry%%|*}" "${entry#*|}"
    done

    printf "${YELLOW}Updating Helm repos${RESET}\n\n"
    helm repo update

    printf "${YELLOW}Creating required namespaces${RESET}\n\n"
    for ns in "${namespaces[@]}"; do
      # idempotent: no error if the namespace already exists
      kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
    done

    run_releases install
    printf "${GREEN}Install completed${RESET}\n\n"
    ;;
  up)
    printf "${YELLOW}Updating Helm repos${RESET}\n\n"
    helm repo update

    run_releases upgrade
    printf "${GREEN}Upgrade completed${RESET}\n\n"
    ;;
  *)
    echo "Please type 'in' (install) or 'up' (upgrade)"
    exit 1
    ;;
esac


