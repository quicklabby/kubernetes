# K3s Mini Cluster Homelab

This project involves the configuration of a **3-node mini cluster**, featuring:

- **Metallb** load balancer configured via BGP  
- **Traefik** as the Ingress Controller  
- **Cert-Manager** for automated Let's Encrypt certificate management using the DNS challenge method with Cloudflare  

---

## Hardware Components

- **Pfsense Appliance**  
- **ASUS Mini PC** (running Proxmox with 2 VMs as worker nodes)  
- **Ryzen AI 9 Mini PC** (Master Node running on Proxmox)  
- **Cisco Switch**  
- **Ubiquity Access Point**  

---

## Cluster Overview

The cluster is designed to operate efficiently within limited hardware resources while maintaining high availability:

- The **ASUS Mini PC** features **32GB RAM** and **2 internal SSDs**, shared with Proxmox. Proxmox hosts **2 VMs** as worker nodes, each allocated **14GB RAM**. To mitigate disk failure risks, each VM is installed on a separate internal SSD.  

- **Persistent storage** for all pods is provided via a **256GB NVMe external drive** connected through USB 3.1 Gen2. This NVMe drive is mounted as an **NFS volume** on Proxmox and shared between the worker nodes to simplify backups and replacements.  

- The **Master Node**, the **Ryzen AI 9 Mini PC**, runs the **etcd database** and is **tainted** to prevent workloads from scheduling on it, focusing exclusively on cluster management and orchestration.  

This configuration ensures reliable operation of a **K3s cluster**, with separate storage for critical components and dedicated resources for both master and worker nodes.

To enhance security, IP whitelisting is implemented using IngressRoute Custom Resources, restricting access to certain services based on client IP addresses.

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
- Ubiquity Unifi Network Application 
- Webtop
- Shinobi
- Frigate
- Home Assistant
- Collabora Online (Nextcloud Integrated)
- Actual Budget
- Firefly III

Applications Database:
- Mariadb
- Mongodb

Monitoring/Logs:
- Grafana/Alloy
- Loki
- InfluxDB
- Prometheus
- Node Exporter (Deprecated in the setup)

CI/CD
- ArgoCD

----------------------------

## Automated K3s Deployment: Install/Upgrade and Uninstall via Ansible Playbooks:

https://github.com/quicklabby/Ansible-Automation-K3s-Deployment-Playbook/tree/main

Automated Helm installation/upgrade bash script:

[helm-install-upgrade.sh](https://github.com/quicklabby/kubernetes/blob/main/helm-install-upgrade.sh)

## Manual Installation Steps:

Step 1:
  K3s installation

1. Install K3s on the master node (Traefik and metallb will be installed later with custom values):

For ETCD database:
```curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --cluster-init --disable=traefik --disable=servicelb" sh -s -```

For default sqlite (Recommended for Raspberry Pi with SD card)
```curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable=traefik --disable=servicelb" sh -s -``` 

(If needed, copy /etc/rancher/k3s/k3s.yaml to your user area ~/.kube/config (permissions 600), and add ```export KUBECONFIG=~/.kube/config``` to your ~/.bashrc.

3. Get your token for worker nodes deployment:
```cat /var/lib/rancher/k3s/server/node-token```

4. Install K3s on the worker nodes:
```curl -sfL https://get.k3s.io | K3S_URL=https://myserver:6443 K3S_TOKEN=mynodetoken sh -```

https://docs.k3s.io/quick-start

TO UPGRADE k3s:

Re-run the installation commands on each node at time starting from the master node. Before proceed with the installaton run the kill all script on each node:
```/usr/local/bin/k3s-killall.sh```

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

How to create a DNS token with Cloudflare: 
https://cert-manager.io/docs/configuration/acme/dns01/cloudflare/

----------------------------

Step 6 (Optional):
   Authentik installation via helm with customized values

1. ```helm repo add authentik https://charts.goauthentik.io```
2. ```helm repo update```
3. ```helm install authentik authentik/authentik -f values.yaml```

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

https://argo-cd.readthedocs.io/en/stable/getting_started/

----------------------------

Step 8 (Optional):
   Install keel via helm with customized values for automatic container image updates
   
1. ```helm repo add keel https://charts.keel.sh ```
2. ```helm repo update```
3. ```helm upgrade --install keel --namespace=kube-system keel/keel -f keel-values.yaml```
4. Add annotations for keel as needed on your deployment yaml

https://keel.sh/docs/#deploying-with-kubectl

----------------------------

Step 7 (Optional)
   Install kube-state-metrics for Prometheus and Grafana monitoring
   
1. ```helm repo add prometheus-community https://prometheus-community.github.io/helm-charts ```
2. ```helm repo update```
3. ```helm install my-kube-state-metrics prometheus-community/kube-state-metrics```

https://artifacthub.io/packages/helm/prometheus-community/kube-state-metrics

----------------------------
