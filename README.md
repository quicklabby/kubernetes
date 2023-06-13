# K3s Cluster Homelab
3 Nodes Cluster with Metallb load balancer via BGP and Traefik as Ingress Controller. Cert Manager automates Letsencypt certificate with DNS challenge over Cloudflare.

Hardware Used:

   - Pfsense box
   - ASUS mini PC (Proxmox with 2 VMs as worker nodes)
   - Raspberry Pi4 8GB RAM (Tainted Master Node)
   - Cisco switch
   - Ubiquity AP

This is a small project I created to learn kubernetes by running a K3s cluster with limited hardware, one Asus mini PC and a Raspberry Pi 3B+.
The Asus mini PC has 2x SSD installed and 32GB of RAM shared with Proxmox, which runs 2 VMs with 14GB RAM allocated for each node.
Since only one mini pc is not enough to run a HA cluster, I installed each node on different SSDs, at least in case of a disk failure one of the node should still running.
All the pods persistent data is retained in an external 256GB NVME volume attached to the Asus mini pc via a 3.1 gen2 USB, shared between the 2 worker nodes for easy backup/replacement in case of failure.
The external NVME is attached to Proxmox and the worker nodes as a NFS volume.
The Rasperry Pi 3B+ has a 128GB SD card installed and acts as a tainted master node as all the pods are scheduled in the workers nodes only.

Webserver:
- Nginx

LoadBalancer/Ingress/SSL/Auth:
- Metallb
- Traefik
- Cert-manager 
- Authentik

Media/Cloud:
- Plex
- Tautulli
- Nextcloud

Utilities/tools:
- Heimdall 
- Ubiquity Unifi Controller
- Webtop
- Shinobi 

Applications Database:
- Mariadb

Monitoring/Logs:
- Grafana
- InfluxDB
- Prometheus
- Node Exporter
- Telegraf

CI/CD
- ArgoCD

----------------------------

---- INSTALLATION STEPS ----

Step 1:
  K3s installation

1. Install K3s on the master node :
```curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik,servicelb" sh -```  (Traefik and metallb will be installed later with custom values)
(If needed, copy /etc/rancher/k3s/k3s.yaml to your user area ~/.kube/config (permissions 600), and add ```export KUBECONFIG=~/.kube/config``` to your ~/.bashrc.

2. Get your token for worker nodes deployment:
```cat /var/lib/rancher/k3s/server/node-token```

3. Install K3s on the worker nodes:
```curl -sfL https://get.k3s.io | K3S_URL=https://myserver:6443 K3S_TOKEN=mynodetoken sh -```

https://docs.k3s.io/quick-start

----------------------------

Step 2:
   Install Metallb desired version with BGP values file 

```kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.9/config/manifests/metallb-frr.yaml -f bgpconfig.yaml```
(bgpconfig values includes pfsense neightbor configuration for the metallb frr yaml)

https://metallb.universe.tf/installation/

----------------------------

Step 3:
   Traefik installation via helm with customized values

1. ```helm repo add traefik https://traefik.github.io/charts```

2. ```helm repo update``` 

3. ```kubectl create namespace traefik```

4. ```helm install --namespace=traefik traefik traefik/traefik -f values.yaml``` 
   
https://artifacthub.io/packages/helm/traefik/traefik

----------------------------

Step 4:
   Certmanager Installation

1. ```kubectl create namespace cert-manager```

2. Add helm repo:
```helm repo add jetstack https://charts.jetstack.io```

3. Update helm repo:
```helm repo update```

4. Install certmanager and apply values with cdrs:
```helm install cert-manager jetstack/cert-manager --namespace cert-manager --values=values.yaml --version v1.9.1```

https://artifacthub.io/packages/helm/cert-manager/cert-manager

----------------------------

Step 5:
   Deploy Cert-manager secret and Letsencrypt certificate for staging/production with cloudflare DNS
   
1. Install ```certmanager-secret.yaml``` manifest with your DNS Cloudflare token

2. Deploy  ```prod-deploy.yaml``` and ```yourdomain-prod-deploy.yaml``` with your chosen domain (for testing purposes, you can use the ```staging-deploy.yaml``` and ```yourdomain-stage-deploy.yaml```)

----------------------------

Step 6 (Optional):
   Authentik installation via helm with customized values

1. ```helm repo add authentik https://charts.goauthentik.io```
2. ```helm repo update```
3. ```helm upgrade --install authentik authentik/authentik -f values.yaml```

https://goauthentik.io/docs/installation/kubernetes
https://artifacthub.io/packages/helm/goauthentik/authentik

----------------------------

Step 7 (Optional):
   Install ArgoCD via helm with customized values
   
1. ```helm repo add argo https://argoproj.github.io/argo-helm```
2. ```helm repo update```
3. ```kubectl create namespace argocd```
4. ```helm install argocd argo/argo-cd  --namespace argocd -f argocd-values.yaml```
5. Apply traefik ingress
