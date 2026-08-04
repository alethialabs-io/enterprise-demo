# BYO-IaC drift probes

Five tiny OpenTofu root modules — one per cloud — that exist to prove a single Alethia
claim end to end:

> Alethia keeps re-proving your infrastructure after the first apply, and a change made
> **outside** Alethia is detected — and then healed.

This is the *bring-your-own IaC* path: your own module, in your own repo, applied by
Alethia's runner. On the four managed clouds Alethia never asks for a cloud key — the
runner authenticates keylessly via federation — and Alethia holds the state, not you.

## Layout

```
iac/
  drift/aws  drift/azure  drift/gcp  drift/alibaba  drift/hetzner   the probes
  blocked/                                                          the NEGATIVE fixture
```

`blocked/` is meant to be **refused**. It declares a provider that is not on Alethia's
allowlist, so a deploy pointed at it must fail at the static gate before `tofu init`
resolves anything. It exists because "the deploy succeeded" is not evidence that the gate
checked anything — a gate that passes everything produces exactly that evidence. Do not
add its provider to any allowlist to "fix" it.

## What a leg proves

```
clone at a pinned SHA
  → fail-closed provider-allowlist gate (iacsafety)     ← blocked/ proves this refuses
  → plan
  → signed verify receipt over the plan JSON
  → apply
  → state written to Alethia's state proxy   (never to a backend you configure)
  → …
  → mutate drift_marker OUT OF BAND          (the step below)
  → refresh-only DETECT_DRIFT  → DRIFTED
  → re-apply the SAME pinned commit → healed → in sync
  → DESTROY, state cleared
```

The out-of-band mutation is what makes this non-vacuous. Re-running a plan against an
unchanged pinned commit re-proves the *pipeline*; only an induced change proves the
**posture actually flips**. And detection without convergence is half a claim, which is
why the heal step is part of the loop rather than an optional extra.

## Two deliberate omissions

Both are load-bearing. Do not add either.

| Omitted | Why |
|---|---|
| a `backend` block | The runner injects an HTTP state-proxy override at `init`. A backend here fights it — and Alethia holding the state is the point. |
| a `cluster_name` output | That output is the signal that makes the runner continue into the kubeconfig → CNI → ArgoCD tail. Without it the run stops right after state-to-proxy, so **no cluster is provisioned**. |

## Cost

Each module owns exactly one resource, chosen to be the cheapest thing on that cloud that
can genuinely drift. Four are free outright; the fifth is an empty bucket, and object
storage is billed on what you put in it — nothing is ever put in it.

| cloud | resource | drifts via | cost |
|---|---|---|---|
| `drift/aws/` | `aws_ssm_parameter` (Standard tier) | its `value` | free |
| `drift/azure/` | empty `azurerm_resource_group` | a tag | free |
| `drift/gcp/` | `google_compute_project_metadata_item` | its `value` | free |
| `drift/alibaba/` | empty `alicloud_oss_bucket` | a tag | ~free (nothing is stored) |
| `drift/hetzner/` | empty `hcloud_placement_group` | a label | free ([Hetzner: "We do not charge for our Cloud Placement Groups"](https://docs.hetzner.com/cloud/placement-groups/overview/)) |
| `blocked/` | — | — | free (never applied) |

No cluster, no VM, no NAT gateway, no load balancer.

## Inducing drift

Run **after** the first successful apply and **before** the next `DETECT_DRIFT`. Each
command changes the one value tofu believes it owns. `drift_target` is a module output, so
you never have to guess the name.

**AWS** — `--type String` is kept so the same command works whether the parameter is being
created or updated. (Changing an existing parameter's *type* would raise
`HierarchyTypeMismatchException`; we never change it.)

```sh
aws ssm put-parameter --overwrite \
  --name "$(tofu output -raw drift_target)" \
  --type String --value "drifted-$(date +%s)"
```

**Azure** — merges: other tags on the group survive. `--force-string` stops the CLI
coercing a value that happens to look like JSON into a non-string.

```sh
az group update \
  --name "$(tofu output -raw drift_target)" \
  --force-string \
  --set "tags.drift_marker=drifted-$(date +%s)"
```

**GCP** — merges: [only the metadata keys you provide are
mutated](https://docs.cloud.google.com/sdk/gcloud/reference/compute/project-info/add-metadata).
`gcloud` does **not** read `GOOGLE_PROJECT` (that is a Terraform provider variable), so
pass `--project` or set `CLOUDSDK_CORE_PROJECT`.

```sh
gcloud compute project-info add-metadata \
  --metadata "$(tofu output -raw drift_target)=drifted-$(date +%s)"
```

**Alibaba** — the key/value separator is `#`, not `=`. `--region` is required in an
unattended context: `aliyun oss` builds its endpoint as `oss-<region>.aliyuncs.com` and
hard-errors when neither the flag nor a profile region resolves.

> ⚠ Unlike the other four, this one **replaces the whole tag set** (`--method put` maps to
> `PUT /?tagging`), so it also drops the module's three descriptive tags. That is still a
> genuine out-of-band change to the probe resource, and the heal apply restores all four.

```sh
aliyun oss bucket-tagging --method put --region "$ALIBABA_REGION" \
  "oss://$(tofu output -raw drift_target)" \
  "drift_marker#drifted-$(date +%s)"
```

**Hetzner** — merges into the existing label map. `--overwrite` is required: without it the
CLI refuses an existing key, which in CI looks like a broken probe rather than a guard.

```sh
hcloud placement-group add-label --overwrite \
  "$(tofu output -raw drift_target)" \
  "drift_marker=drifted-$(date +%s)"
```

The next refresh-only plan must report the change. If it reports **no** drift, that is a
real defect in the drift path — not a flaky probe.

> Do **not** induce drift by editing `drift_marker` and re-applying. That is an ordinary
> tofu change; it proves nothing about detecting what happened behind Alethia's back.

## Healing

Re-apply the **same pinned commit**. Nothing else changes: the module still declares
`drift_marker = "baseline"`, so the apply moves the live value back and the next
refresh-only plan reports in sync again.

## Variables

Every drift module takes the same four, and all four have defaults, so a module plans with
no input at all:

| variable | source |
|---|---|
| `alethia_project` | injected by the runner as `TF_VAR_alethia_project` |
| `alethia_environment` | injected by the runner as `TF_VAR_alethia_environment` |
| `drift_marker` | leave at `baseline` — mutate out of band instead |
| `name_suffix` | disambiguator when several tenants share one account |

`drift/azure` also takes `location` (default `westeurope`) for its resource group.

The `alethia_context` output echoes the first two back, which is how a leg proves the
runner's variable injection actually reached the module rather than silently defaulting.

## Validating locally

No credentials needed — `validate` does not contact the cloud:

```sh
cd iac/drift/aws && tofu init -backend=false && tofu validate
```

`blocked/` is the exception: it validates fine (it is valid HCL) and is *supposed* to fail
Alethia's gate, not OpenTofu's parser. Never `apply` it.
