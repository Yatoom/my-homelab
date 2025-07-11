# Homelab

## Host system
Kubernetes is running on an Optiplex 3070 with an i7-9700, 16GB RAM and 1.5TB of storage.

### Microk8s
The cluster is running on microk8s. A few things have been directly enabled using `microk8s addons`.

```
addons:
  enabled:
    argocd               # (community) Argo CD is a declarative continuous deployment for Kubernetes.
    openebs              # (community) OpenEBS is the open-source storage solution for Kubernetes
    cert-manager         # (core) Cloud native certificate management
    community            # (core) The community addons repository
    dns                  # (core) CoreDNS
    ha-cluster           # (core) Configure high availability on the current node
    helm                 # (core) Helm - the package manager for Kubernetes
    helm3                # (core) Helm 3 - the package manager for Kubernetes
    hostpath-storage     # (core) Storage class; allocates storage from host directory
    ingress              # (core) Ingress controller for external access
    metrics-server       # (core) K8s Metrics Server for API access to service metrics
    observability        # (core) A lightweight observability stack for logs, traces and metrics
    storage              # (core) Alias to hostpath-storage add-on, deprecated
```

### Fixes
- Note: `microk8s enable observability --kube-prometheus-stack-version=72.7.0` reduced the memory usage by more than half. It uses a new version with more .
- Due to some issues with [Argocd](https://github.com/bitnami/charts/issues/28893#issuecomment-2306499431) I was not able to deploy mlflow via an ArgoCD app. Instead I ran the following commands: `helm install mlflow oci://registry-1.docker.io/bitnamicharts/mlflow --set postgresql.auth.password=<password> --set postgresql.auth.username=jerry --set tracking.auth.password=<password>` and since I don't have a loadbalancer: `kubectl patch svc mlflow-tracking -n default -p '{"spec": {"type": "ClusterIP"}}'`


### Apps
- Glance ![](screenshots/glance.png)
- ArgoCD ![](screenshots/argocd.png)
- Open WebUI ![](screenshots/open-webui.png)
- SonarQube ![](screenshots/sonarqube.png)
- Grafana ![](screenshots/grafana.png)
- N8N ![](screenshots/n8n.png)
- Jellyfin ![](screenshots/jellyfin.png)
- Koel ![](screenshots/koel.png)
- Authentik ![](screenshots/authentik.png)

### Secrets
Secrets are secured with [sealed-secrets](https://github.com/bitnami-labs/sealed-secrets). A secret file needs to be converted using: `kubeseal -f secret.yaml -o yaml > sealed.yaml`. `kubeseal` automatically uses the `kubectl` configuration to connect to the cluster.
