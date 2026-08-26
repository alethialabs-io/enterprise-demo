# `iac/` — bring-your-own OpenTofu fixtures for Alethia's e2e

These modules are not part of the enterprise demo. They exist so Alethia can prove, against a real
cloud, that it runs **a customer's own OpenTofu** correctly — code in a repository Alethia does not
own the state of, which is the whole point of bring-your-own IaC.

They are referenced by `test/e2e/t2_byo_iac.go` in the Alethia repo, which defaults to this repo at
`iac/drift/<provider>` and `iac/blocked`.

## What each module must keep being

`drift/<provider>` — one mutable resource, and nothing else:

| requirement | why it is not incidental |
|---|---|
| **no `backend` block** | the runner forces Alethia's HTTP state proxy by writing an override; a backend here would be the thing it overrides. The absence is what makes "state never reached the customer's own sink" checkable |
| **`alethia_context` output** | equals `<project>/<environment>` only if the runner's frozen `TF_VAR_alethia_*` injection arrived. A module that fell back to the variable defaults emits `local/dev` instead |
| **no `cluster_name` output** | that single omission keeps Alethia's whole post-apply spine off — the kubeconfig → CNI → ArgoCD tail runs only when `cluster_name` is non-empty. Asserted mechanically against the state |
| **exactly one drift probe** | drift must be attributable to *this* resource, so an unrelated wobble elsewhere cannot be credited as the induced change |
| **cheap to hold** | every probe is free or near-free: a placement group, an SSM parameter, a metadata item, an empty resource group, an empty bucket. Proving a posture should not bill by the hour |

`blocked` — declares a provider **not** on the allowlist and provisions nothing. It is what stops the
gate's assertion being *"the deploy succeeded, so presumably something was checked"*.

## Adding a cloud

Add its directory here and its probe-resource row in `byoIacProbeResourceType`. The path is derived
(`iac/drift/<provider>`), so there is no third place to remember.
