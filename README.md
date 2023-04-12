# K3s Kubernetes Cluster Homelab
3 Nodes Cluster with Metallb via BGP and Traefik as Ingress Controller. Cert Manager is used for automated Letsencypt certificate and DNS challenge over Cloudflare

Hardware Used:

   - Pfsense box
   - ASUS mini PC (Proxmox with 2 VMs as worker nodes)
   - Raspberrypi 3B+ (Tainted Master Node)
   - Cisco switch
   - Ubiquity AP

This is a small project I created to learn kubernetes by running a K3s cluster with limited hardware, one Asus mini PC and a Raspberrypi 3B+.
The Asus mini PC has 2x SSD installed and 32GB of RAM shared with Proxmox, which run 2 VMs with Oracle Linux installed and 14GB RAM allocated for each node.
Since only one mini pc is not enough to run a HA cluster, I installed each node on different SSDs at least in case of a disk failure one of the node should still running.
All the pods persistent data is retained in an external 256GB NVME volume attached to the Asus mini pc via 3.1 gen2 USB, shared between the 2 worker nodes for easy backup and replacement in case of failure.
The external NVME is attached to Proxmox and the worker nodes as a NFS volume.
The Rasperrypi 3B+ has a 128GB SD card installed with raspbian OS that act as a tainted master node as all the pods are allocated in the workers nodes only.

----------------------------

---- INSTALLATION STEPS ----

Step 1:
##K3s installation##

1. Install K3s on the master node :
```curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -```  (Traefik is installed later via helm with custom values)

2. Get your token for worker nodes deployment:
```cat /var/lib/rancher/k3s/server/node-token```

3. Install K3s on the worker nodes:
```curl -sfL https://get.k3s.io | K3S_URL=https://myserver:6443 K3S_TOKEN=mynodetoken sh -```

https://docs.k3s.io/quick-start

----------------------------

Step 2:
###Metallnstallation with BGP values file##

```kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.9/config/manifests/metallb-frr.yaml -f bgpconfig.yaml```
(bgpconfig values includes pfsense neightbor configuration for the metallb frr yaml)

https://metallb.universe.tf/installation/

----------------------------

Step 3:
###Traefik installation###

1. ```helm repo add traefik https://traefik.github.io/charts```

2. ```helm repo update``` 

3. ```kubectl create namespace traefik```

4. ```helm install --namespace=traefik traefik traefik/traefik -f values.yaml``` 
   
https://artifacthub.io/packages/helm/traefik/traefik

----------------------------

Step 4:
###Certmanager Installation###

1. ```kubectl create namespace cert-manager```

2. Install correct version:
```kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.9.1/cert-manager.crds.yaml```

3. Apply values:
```helm install cert-manager jetstack/cert-manager --namespace cert-manager --values=values.yaml --version v1.9.1```

https://cert-manager.io/docs/installation/

----------------------------

Step 5:
- Deploy Letsencrypt certificate for staging/production with cloudflare DNS

----------------------------

Step 6 (Optional):
- Authentik installation is done with helm and customized values:

1. ```helm repo add authentik https://charts.goauthentik.io```
2. ```helm repo update```
3. ```helm upgrade --install authentik authentik/authentik -f values.yaml```

https://goauthentik.io/docs/installation/kubernetes
https://artifacthub.io/packages/helm/goauthentik/authentik
