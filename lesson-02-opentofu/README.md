---
title: "OpenTofu"
type: repo
difficulty: intermediate
tier: free
platform: "Linux Foundation"
url: "https://github.com/opentofu/opentofu"
tags: ["opentofu", "terraform", "iac", "open-source"]
stars: 23000
---

# OpenTofu

## Overview

OpenTofu is an open-source Infrastructure as Code tool forked from Terraform and managed by the Linux Foundation. The project was born in August 2023 after HashiCorp changed Terraform's license from the Mozilla Public License (MPL 2.0) to the Business Source License (BSL 1.1), which restricted commercial use by competing vendors. A broad coalition of companies and individual contributors launched the OpenTofu manifesto, and the Linux Foundation accepted the project under its stewardship to guarantee it would remain truly open source under the MPL 2.0 license indefinitely.

OpenTofu maintains drop-in compatibility with Terraform 1.5.x configurations, providers, and modules, making migration straightforward for existing users. Beyond compatibility, the project has introduced differentiating features such as client-side state encryption, early variable and locals evaluation, and a community-driven provider registry at registry.opentofu.org. The governance model follows an open, committee-based structure where decisions are made transparently through RFCs and community votes. For teams evaluating their IaC tooling strategy, OpenTofu provides a credible, community-governed alternative that eliminates vendor lock-in concerns while preserving the HCL workflow engineers already know.

## Prerequisites

- Familiarity with Infrastructure as Code concepts and HCL (HashiCorp Configuration Language) syntax
- A GitHub account and basic experience with Git workflows (cloning, branching, pull requests)
- Access to an AWS, GCP, or Azure account (free tier sufficient) for testing provider configurations
- Command-line proficiency on Linux, macOS, or WSL (package managers, environment variables, PATH configuration)

## Key Takeaways

1. **License-free IaC** - OpenTofu is MPL 2.0 licensed with a Linux Foundation pledge to remain open source, eliminating BSL restrictions on commercial and competitive use
2. **State encryption at rest** - OpenTofu natively supports client-side state encryption, protecting sensitive values in state files without external tooling or wrapper scripts
3. **Drop-in Terraform compatibility** - Existing Terraform 1.5.x configurations, providers, and modules work with OpenTofu with minimal or no changes, lowering the migration barrier
4. **Community-governed registry** - The OpenTofu Registry (registry.opentofu.org) mirrors Terraform providers and modules while operating under open governance, preventing single-vendor control of the ecosystem
5. **Transparent development process** - All major features go through public RFCs, and the project's steering committee operates with published meeting notes and community-elected members

## How to Use

### Step 1: Install OpenTofu

1. **macOS (Homebrew)**:
   ```bash
   brew install opentofu
   ```
2. **Linux (Debian/Ubuntu)**:
   ```bash
   # Prefer the official OpenTofu package repository instructions for your distro.
   # Verify the repository signing key fingerprint before installing.
   sudo apt-get update
   sudo apt-get install opentofu
   ```
3. **Linux (RPM-based)**:
   ```bash
   # Prefer the official OpenTofu package repository instructions for your distro.
   # Verify the repository signing key fingerprint before installing.
   sudo dnf install opentofu
   ```
4. Verify the installation:
   ```bash
   tofu --version
   ```
5. Explore the CLI — most commands mirror Terraform exactly (`tofu init`, `tofu plan`, `tofu apply`, `tofu destroy`)

### Step 2: Explore the OpenTofu Registry

1. Browse [registry.opentofu.org](https://registry.opentofu.org) and search for a provider you use (e.g., AWS, Azure, GCP, Kubernetes)
2. Note that provider source addresses use the same `registry.opentofu.org` namespace but also accept `registry.terraform.io` references for backward compatibility
3. Review a module listing — compare the documentation structure with what you see on the Terraform registry
4. In a `main.tf` file, declare a provider block:
   ```hcl
   terraform {
     required_providers {
       aws = {
         source  = "hashicorp/aws"
         version = "~> 5.0"
       }
     }
   }
   ```
5. Run `tofu init` and observe how OpenTofu resolves the provider from its registry

### Step 3: Migrate an Existing Terraform Project

1. Locate a simple Terraform project (or create a test project with an S3 bucket or resource group)
2. Ensure you are on Terraform 1.5.x or check compatibility notes in the [OpenTofu migration guide](https://opentofu.org/docs/intro/migration/)
3. Replace `terraform` commands with `tofu`:
   - `tofu init` (re-initializes providers from the OpenTofu registry)
   - `tofu plan` (generates an execution plan — should match previous Terraform behavior)
   - `tofu apply` (applies changes)
4. If your project uses a remote backend (S3, GCS, Azure Blob), no backend configuration changes are needed — OpenTofu supports the same backends
5. Review the plan output carefully to confirm no unexpected resource changes before applying

### Step 4: Enable Client-Side State Encryption

1. Add an encryption block to your OpenTofu configuration:
   ```hcl
   terraform {
     encryption {
       key_provider "pbkdf2" "my_passphrase" {
         passphrase = var.state_passphrase
       }
       method "aes_gcm" "my_method" {
         keys = key_provider.pbkdf2.my_passphrase
       }
       state {
         method = method.aes_gcm.my_method
       }
       plan {
         method = method.aes_gcm.my_method
       }
     }
   }
   ```
2. Define the passphrase variable and supply it via environment variable (`TF_VAR_state_passphrase`) or a `.tfvars` file excluded from version control
3. Run `tofu apply` — the state file is now encrypted at rest with AES-GCM
4. Inspect the state file (`terraform.tfstate`) to confirm its contents are encrypted and unreadable without the key
5. For production use, consider AWS KMS, GCP KMS, or OpenBao key providers instead of passphrase-based derivation

### Step 5: Explore the Project and Contribute

1. Clone the OpenTofu repository:
   ```bash
   git clone https://github.com/opentofu/opentofu.git
   ```
2. Read the `CONTRIBUTING.md` file to understand the development workflow, code style, and testing requirements
3. Browse open issues labeled `good-first-issue` for approachable contributions
4. Review the RFC process under the `rfc/` directory — this is where major design decisions are proposed and debated publicly
5. Join the OpenTofu community on Slack and GitHub Discussions to ask questions, propose ideas, and follow the project roadmap

## Practice Notes

- Treat the repository as source material to inspect, not just clone. Review the README, release history, examples, issues, license, and maintenance signals before deciding whether to reuse it.
- Translate the lesson into an IaC operating habit: repeatable plans, state safety, reviewable diffs, module boundaries, policy checks, and cleanup of any billable resources.
- Completion checkpoint: you can adapt the pattern to a second environment, identify its tradeoffs, and explain the operational risks it introduces.
- Portfolio artifact: create a short note titled "OpenTofu - applied takeaway" with the scenario you used, the decision you made, and one follow-up task you would assign to yourself or a team.

## Deliverable

Produce an OpenTofu migration readiness checklist for one Terraform project:

- Current Terraform version, provider versions, backend type, and state location
- Compatibility result for `tofu init` and `tofu plan`
- Registry or provider source changes required, if any
- State encryption recommendation with key provider choice and secret handling notes
- A go/no-go decision with the top three migration risks

## Validation

Run the checks in a disposable copy of the project:

```bash
terraform init -backend=false
terraform validate
tofu init -backend=false
tofu validate
tofu plan -out=tofu.plan
```

Compare the Terraform and OpenTofu validation results. If a remote backend is involved, add a state strategy note explaining whether the migration uses existing state, a copied state file, or a new backend path.

## Self-Assessment

- What specific compatibility issue would block this project from moving to OpenTofu?
- Which state data is sensitive enough to require encryption?
- How would you roll back if the first OpenTofu plan differs from the Terraform plan?
- What evidence would convince a reviewer that this migration is low risk?

## Related Resources

- [OpenTofu GitHub Repository](https://github.com/opentofu/opentofu) - Source code, issues, RFCs, and contribution guidelines
- [OpenTofu Official Documentation](https://opentofu.org/docs/) - Installation guides, configuration reference, and migration instructions
- [OpenTofu Registry](https://registry.opentofu.org) - Community-governed provider and module registry with full Terraform provider compatibility
- [OpenTofu State Encryption Documentation](https://opentofu.org/docs/language/state/encryption/) - Detailed guide on configuring client-side state encryption with various key providers

## Estimated Time

- **Installation and CLI exploration**: 10 minutes
- **Registry exploration and provider setup**: 10 minutes
- **Terraform migration walkthrough**: 10 minutes
- **State encryption configuration**: 15 minutes
- **Total for this lesson**: ~45 minutes
