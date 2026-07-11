# Alethia enterprise demo — Online Boutique

A real 11-service microservices application ([Google's Online Boutique](https://github.com/GoogleCloudPlatform/microservices-demo))
delivered by **Alethia** to a self-owned **Talos / Hetzner** Kubernetes cluster via **GitOps (ArgoCD)**,
alongside the enterprise day-2 add-ons (ingress-nginx · cert-manager · Prometheus/Grafana · in-cluster S3),
promoted across two environments.

- `base/` — the 11 microservices (canonical Online Boutique manifests + kustomization).
- `overlays/dev/` — the **dev** environment (namespace `boutique-dev`).
- `overlays/staging/` — the **staging** environment (namespace `boutique-staging`, HA frontend).

ArgoCD syncs `overlays/dev` and `overlays/staging` as two Applications — same app, two environments, one
cluster you fully own (portable OpenTofu + ArgoCD). Provisioned in minutes on compute-only Hetzner.
