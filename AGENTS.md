# Homelab overview

## Cluster and deployment model

- The cluster is MicroK8s on a single OptiPlex 3070 host (see [README.md](./README.md) for the documented hardware and enabled MicroK8s add-ons).
- MicroK8s add-ons provide Argo CD, ingress, cert-manager, DNS, metrics, observability, and storage. OpenEBS and host-path storage are enabled.
- Argo CD `Application` resources in `argo-app/applications/` install Helm charts into the cluster. These Applications generally use automated sync with pruning and self-healing.
- Other directories under `argo-app/` contain ordinary Kubernetes manifests (Deployments, Services, Ingresses, PVs/PVCs, and Secrets). They describe workloads, but this repository does not establish that every such directory is automatically synced by Argo CD.
- This is a configuration overview, not a live cluster inventory. A manifest in the repository does not by itself prove a service is currently running.

## Services

### Installed from Helm charts through Argo CD

- **Authentik** (`authentik`): identity provider; chart enables PostgreSQL and Redis. Its ingress is configured for `auth.jerryberry.nl`.
- **n8n** (`n8n`): workflow automation; chart ingress uses `n8n.jerryberry.nl`.
- **Nextcloud** (`nextcloud`): chart-based file service; configured with a persistent claim and ingress at `nextcloud.jerryberry.nl`.
- **Open WebUI** (`open-webui`): chart-based chat UI; configured for Authentik OIDC and routed at `chat.jerryberry.nl`.
- **Jellyfin** (`media`): chart-based media server with a NodePort service and persistent configuration/media claims; routed at `movies.jerryberry.nl`.
- **Sealed Secrets** (`kube-system`): controller for decrypting checked-in SealedSecret resources.
- **Istio ambient components** (`istio-system`): Istio base, CNI, `istiod`, and `ztunnel` charts at version 1.26.1. Some application namespaces are labeled for ambient dataplane mode.

### Workloads described by Kubernetes manifests

- **Glance** (`glance`): single-replica dashboard, configured by a ConfigMap and exposed through Ingress at `glance.jerryberry.nl`.
- **Uptime Kuma** (`uptime-kuma`): single-replica status monitor with a persistent data claim; Ingress at `uptime.jerryberry.nl`.
- **Koel and MariaDB** (`koel`): single-replica music application and database, with persistent storage; Ingress at `music.jerryberry.nl`.
- **Media utilities** (`media`): single-replica Sonarr, Radarr, Prowlarr, qBittorrent, and FlareSolverr Deployments with ClusterIP Services. The central Ingress routes them at `sonarr.jerryberry.nl`, `radarr.jerryberry.nl`, `prowlarr.jerryberry.nl`, `qbittorrent.jerryberry.nl`, and `flaresolverr.jerryberry.nl`. Sonarr, Radarr, and qBittorrent share the media/downloads claim where configured.
- **Outline VPN** (`outline-system`): single-replica Shadowbox Deployment. Client ports 30400 (legacy keys) and 30443 (new keys) are exposed on matching NodePorts for TCP and UDP; management is on NodePort 30600/TCP. The server uses a mounted TLS Secret and persistent configuration. `scripts/outline-manager-json.sh` builds the Manager setup JSON from the live deployment and TLS Secret without rotating certificates.
- **Kiali**: Kubernetes resources are present in `argo-app/applications/istio/kiali.yaml`; check cluster state before treating it as installed.

## Traffic, certificates, and storage

- HTTP(S) application access is primarily through Kubernetes Ingress resources and the MicroK8s ingress controller. The manifests request TLS certificates from the `lets-encrypt` cert-manager ClusterIssuer.
- `argo-app/ingress/ingress.yaml` routes several app hostnames through `ExternalName` Services to their in-cluster backends. Separate Ingress manifests handle other hosts, including Argo CD, Grafana, and Prometheus.
- Persistent data uses a mix of OpenEBS host-path claims and manually bound host-path PVs. The latter use host directories such as `/mnt/ssd/shared-media`, `/mnt/ssd/music-media`, and `/mnt/ssd/nextcloud-media`; these are local to the MicroK8s node.
- The MicroK8s observability add-on provides the Prometheus/Grafana stack; repository manifests add ingress and PodMonitor/ServiceMonitor resources.

## Notable configuration caveats

- `argo-app/applications/mlflow.yaml`, `sonarqube.yaml`, `kagent.yaml`, and `kagent-crds.yaml` contain commented-out Argo CD Application definitions. Do not describe them as Argo-managed based on these files. The README documents MLflow as a manual Helm installation; current runtime status is not established by this repository.
- When changing services, inspect the related Application and workload, service, ingress, and storage manifests together. Keep hostnames, backend Service names, namespaces, and PVC references consistent.
- Secret material is managed with Sealed Secrets in this repository. Do not copy decrypted credentials or secret values into documentation.
