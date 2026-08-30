# Online Boutique — the isolation ladder

[Google's Online Boutique](https://github.com/GoogleCloudPlatform/microservices-demo): twelve
microservices, delivered by Alethia to **five environments at four isolation levels, on one
cluster**.

The point of this example is the one sentence it exists to prove:

> The isolation level is a **placement** decision, not a **procurement** decision.

## The five environments

| Environment | Placement | Namespace | What it costs |
|---|---|---|---|
| `prod` | `dedicated` | — | Owns the Fabric. This is the only one that buys a cluster. |
| `staging` | `vcluster` | `boutique-staging` | Its own Kubernetes API server, on the same nodes. |
| `dev-1` | `namespace` | `boutique-dev-1` | A namespace. |
| `dev-2` | `namespace` | `boutique-dev-2` | A namespace. |
| `dev-3` | `namespace` | `boutique-dev-3` | A namespace. |

Only `prod` provisions infrastructure. The other four are placed onto the Fabric it owns, so
`alethia cluster list` returns **one** cluster and the bill has one line on it.

A vcluster is a **control-plane** boundary, not a hard workload boundary — its pods schedule on the
host's nodes. Being precise about the one thing that is not a hard boundary is what makes the rest of
the isolation story credible.

## Layout

```
base/                 the twelve services, canonical upstream manifests
overlays/prod/        production tier
overlays/staging/     frontend at 2 replicas
overlays/dev-1..3/    loadgenerator scaled to 0
```

Each overlay sets its own `namespace:`, which **must** match the namespace its Alethia environment
declares — the tenant AppProject refuses a sync that lands anywhere else. That refusal is the
isolation, and it is worth showing.

The dev tiers switch the load generator off. It is pure synthetic CPU: three copies of it would
inflate the node count without making any tier more browsable.

## Sizing

Five tiers means **six** copies of the application, because the staging tier is placed a second time
inside its vcluster and those pods schedule on the host. At roughly 1.7 vCPU / 1.5 GB per copy, plus
ArgoCD, the vcluster control plane and the platform rail, the floor is about **12 vCPU / 12 GB**.

Four `cx33` on Hetzner (16 vCPU / 32 GB, ~€0.06/hr for the cluster) runs it with real headroom —
measured at 5–11% CPU with everything converged.

## Running it

See the [enterprise-demo tutorial](https://alethialabs.io/docs/tutorials/enterprise-demo). The short
version: create the project with all five environments, configure the cluster on `prod`, then
`plan` + `apply` **per environment** — `prod` first, because a shared placement needs a Fabric whose
cluster already exists.
