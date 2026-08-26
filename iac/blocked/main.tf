# THE NEGATIVE CASE. This module exists to be REFUSED.
#
# A safety gate that passes everything looks exactly like a safety gate that works, and the only way
# to tell them apart is to hand one something it must reject. So this declares a provider that is
# NOT on iacsafety.DefaultProviderAllowlist, and the e2e leg asserts its job FAILS with a
# provider-not-allowlisted finding — before `tofu init` resolves anything.
#
# Two properties matter and are easy to lose:
#
#   1. IT PROVISIONS NOTHING. There is no resource block. The gate must refuse this on the DECLARED
#      provider alone, so the refusal cannot be confused with a credential that happened to be
#      missing, and a regression cannot quietly create something real in a customer's cloud.
#   2. IT LIVES AT THE SAME PINNED COMMIT as the positive modules. The proof is that the gate
#      distinguishes two modules in one repo at one SHA — not that two different clones behaved
#      differently.
#
# Cloudflare is chosen because it is an entirely legitimate, widely-used provider. The point is that
# the allowlist is an ALLOWLIST — a provider is refused for being absent from it, not for being
# suspicious — and a fixture using something obviously malicious would prove a weaker claim.
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

# Intentionally empty. See above: the refusal must rest on the declaration.
