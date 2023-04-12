# Kubernetes Cluster Homelab
###3 Nodes Cluster Homelab with Metallb via BGP and Traefik as Ingress Controller###

Hardware Used:

   - Pfsense box
   - ASUS mini PC (Proxmox with 2 vm as worker nodes)
   - Rasperrypi 3b+ (Tainted Master Node)
   - Cisco switch
   - Ubiquity AP

---- Installation Steps ----

Step 1:
##K3s installation##

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -  (Traefik is installed later via helm with custom values)

----------------------------

Step 2:
###Metallnstallation with BGP values file##

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.9/config/manifests/metallb-frr.yaml -f bgpconfig.yaml
(bgpconfig values includes pfsense neightbor configuration for the metallb frr yaml)

----------------------------

Step 3:
###Traefik installation###

1. kubectl create namespace traefik

2. helm install --namespace=traefik traefik traefik/traefik --values=values.yaml

----------------------------

Step 4:
###Certmanager Installation###

1. kubectl create namespace cert-manager

2. Install correct version:
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.9.1/cert-manager.crds.yaml

3. Apply values:
helm install cert-manager jetstack/cert-manager --namespace cert-manager --values=values.yaml --version v1.9.1

----------------------------

Step 5:
- Install Letsencrypt certificate for staging/production with cloudflare DNS
