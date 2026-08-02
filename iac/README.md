# BYO-IaC drift probes

Four tiny OpenTofu root modules — one per cloud — that exist to prove a single Alethia
claim end to end:

> Alethia keeps re-proving your infrastructure after the first apply, and a change made
> **outside** Alethia is detected.

This is the *bring-your-own IaC* path: your own module, in your own repo, applied by
Alethia's runner. Alethia never asks for a cloud key — the runner authenticates keylessly
via federation — and Alethia holds the state, not you.

## What a leg proves

```
clone at a pinned SHA
  → fail-closed provider-allowlist gate (iacsafety)
  → plan
  → signed verify receipt over the plan JSON
  → apply
  → state written to Alethia's state proxy   (never to a backend you configure)
  → …
  → mutate drift_marker OUT OF BAND          (the step below)
  → refresh-only DETECT_DRIFT
  → DRIFTED
  → DESTROY, state cleared
```

The out-of-band mutation is what makes this non-vacuous. Re-running a plan against an
unchanged pinned commit re-proves the *pipeline*; only an induced change proves the
**posture actually flips**.

## Two deliberate omissions

Both are load-bearing. Do not add either.

| Omitted | Why |
|---|---|
| a `backend` block | The runner injects an HTTP state-proxy override at `init`. A backend here fights it — and Alethia holding the state is the point. |
| a `cluster_name` output | That output is the signal that makes the runner continue into the kubeconfig → CNI → ArgoCD tail. Without it the run stops right after state-to-proxy, so **no cluster is provisioned**. |

## Cost

Each module owns exactly one resource, chosen to be the cheapest thing on that cloud that
can genuinely drift. Three are free outright; the fourth is an empty bucket, and storage is
billed on what you put in it.

| cloud | resource | drifts via | cost |
|---|---|---|---|
| `aws/` | `aws_ssm_parameter` (Standard tier) | its `value` | free |
| `azure/` | empty `azurerm_resource_group` | a tag | free |
| `gcp/` | `google_compute_project_metadata_item` | its `value` | free |
| `alibaba/` | empty `alicloud_oss_bucket` | a tag | ~free (nothing is stored) |

No cluster, no VM, no NAT gateway, no load balancer.

## Inducing drift

Run **after** the first successful apply and **before** the next `DETECT_DRIFT`. Each
command changes the one value tofu believes it owns. `drift_target` is a module output, so
you never have to guess the name.

**AWS**

```sh
aws ssm put-parameter --overwrite \
  --name "$(tofu output -raw drift_target)" \
  --type String --value "drifted-$(date +%s)"
```

**Azure**

```sh
az group update \
  --name "$(tofu output -raw drift_target)" \
  --set "tags.drift_marker=drifted-$(date +%s)"
```

**GCP**

```sh
gcloud compute project-info add-metadata \
  --metadata "$(tofu output -raw drift_target)=drifted-$(date +%s)"
```

**Alibaba**

```sh
aliyun oss bucket-tagging --method put \
  "oss://$(tofu output -raw drift_target)" \
  "drift_marker=drifted-$(date +%s)"
```

The next refresh-only plan must report the change. If it reports **no** drift, that is a
real defect in the drift path — not a flaky probe.

> Do **not** induce drift by editing `drift_marker` and re-applying. That is an ordinary
> tofu change; it proves nothing about detecting what happened behind Alethia's back.

## Variables

Every module takes the same four, and all four have defaults, so a module plans with no
input at all:

| variable | source |
|---|---|
| `alethia_project` | injected by the runner as `TF_VAR_alethia_project` |
| `alethia_environment` | injected by the runner as `TF_VAR_alethia_environment` |
| `drift_marker` | leave at `baseline` — mutate out of band instead |
| `name_suffix` | disambiguator when several tenants share one account |

The `alethia_context` output echoes the first two back, which is how a leg proves the
runner's variable injection actually reached the module rather than silently defaulting.

## Validating locally

No credentials needed — `validate` does not contact the cloud:

```sh
cd iac/drift/aws && tofu init -backend=false && tofu validate
```
