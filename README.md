# K3s Mini Cluster Homelab
The project involves the configuration of a 3-node mini cluster, incorporating a Metallb load balancer via BGP and Traefik as the Ingress Controller. Cert Manager is employed to automate Let's Encrypt certificate management, utilizing the DNS challenge method over Cloudflare.

Hardware components:

- Pfsense Appliance
- ASUS mini PC (utilizing Proxmox with 2 VMs as worker nodes)
- Raspberry Pi4 with 8GB RAM (designated as the Master Node)  ```Upgraded to a Ryzen AI 365 mini PC with etcd database```
- Cisco switch
- Ubiquity Access Point

This undertaking focuses on establishing a K3s cluster within resource constraints, utilizing an ASUS mini PC and a Raspberry Pi4. The ASUS mini PC features 2 SSDs and 32GB of RAM, shared with Proxmox, which hosts 2 VMs allocated with 14GB RAM each for worker nodes. Given the ASUS mini PC's limitations for high availability clustering, each node is installed on separate internal SSDs to ensure continued operation in the event of one disk failure. Persistent data for all pods is stored on an external 256GB NVME volume, connected to the ASUS mini PC via USB 3.1 gen2 and shared between the worker nodes for simplified backup and replacement procedures. This external NVME volume is mounted to Proxmox and the worker nodes as an NFS volume. The Raspberry Pi4, equipped with a 128GB SD card, serves as a tainted master node, overseeing pod scheduling exclusively within the worker nodes.

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
- Collabora for Nextcloud
- Actual Budget
- Firefly III

Applications Database:
- Mariadb
- Mongodb

Monitoring/Logs:
- Grafana
- InfluxDB
- Prometheus
- Node Exporter

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

1. Install K3s on the master node :
```curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik,servicelb" sh -```  (Traefik and metallb will be installed later with custom values)
(If needed, copy /etc/rancher/k3s/k3s.yaml to your user area ~/.kube/config (permissions 600), and add ```export KUBECONFIG=~/.kube/config``` to your ~/.bashrc.

2. Get your token for worker nodes deployment:
```cat /var/lib/rancher/k3s/server/node-token```

3. Install K3s on the worker nodes:
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
3. ```helm install keel --namespace=kube-system keel/keel -f keel-values.yaml```
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
