# Alethia examples

Runnable references for [Alethia](https://alethialabs.io). Each one is a real workload delivered by
the product to a cluster you own, not a diagram — you can point an Alethia environment at any
directory here and watch it converge.

## What is here

| Example | Shows | Path |
|---|---|---|
| **Online Boutique** | The isolation ladder: five environments at four isolation levels on **one** cluster | [`examples/online-boutique/`](./examples/online-boutique) |
| **BYO-IaC modules** | Customer OpenTofu run through Alethia's verification gate and state proxy — including one that is deliberately refused | [`iac/`](./iac) |

## Layout

```
examples/<name>/          one example, self-contained
  base/                   the application, unmodified upstream where possible
  overlays/<env>/         one Kustomize overlay per environment
iac/                      OpenTofu modules for the BYO-IaC path
```

Each example directory is independent, so an environment points at exactly one overlay and owns
exactly what that overlay declares.

### Why `iac/` sits at the root

It is referenced by fixed paths (`iac/drift/<cloud>`, `iac/blocked`) from Alethia's own end-to-end
suite, which has proven BYO-IaC cells resolving through them. Moving it is a rename with a blast
radius, so it stays put until that is done deliberately rather than as a side effect of tidying.

## Pointing Alethia at an example

An environment declares the repository and the subpath it delivers:

```bash
alethia project component add --project <project> --env prod --kind repositories \
  --set apps_destination_repo=https://github.com/alethialabs-io/alethia-examples \
  --set apps_path=examples/online-boutique/overlays/prod
```

`apps_path` means the same thing on every placement mode — `dedicated`, `vcluster` and `namespace`
all deliver exactly the path they name. That is what lets five environments share one repository
without any of them adopting another's manifests.
