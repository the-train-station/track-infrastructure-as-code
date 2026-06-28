---
title: "Terraform Best Practices"
type: whitepaper
difficulty: intermediate
tier: free
platform: "HashiCorp"
url: "https://developer.hashicorp.com/terraform/language/style"
tags: ["terraform", "best-practices", "iac", "hashicorp"]
---

# Terraform Best Practices

## Overview

Terraform best practices represent the collective wisdom of the infrastructure-as-code community distilled into patterns for writing maintainable, secure, and scalable configurations. As organizations grow their Terraform usage from a handful of resources to hundreds of modules managing production infrastructure, the difference between well-structured and poorly-structured code becomes the difference between confident deployments and operational nightmares. These practices cover the full lifecycle of Terraform development: how to organize code into composable modules, how to manage state safely across teams, how to enforce security policies before resources are provisioned, and how to integrate Terraform into automated CI/CD pipelines.

Adopting these practices early prevents the accumulation of technical debt that plagues many IaC codebases. Module composition enables reuse and consistency across environments. Remote state backends with locking prevent concurrent modification disasters. Variable validation catches misconfigurations before they reach cloud providers. Security scanning tools like tfsec and Checkov shift security left, catching policy violations in pull requests rather than in production audits. Together, these practices transform Terraform from a provisioning script into a reliable engineering discipline that scales with your organization.

## Prerequisites

- Working knowledge of Terraform core concepts (resources, providers, variables, outputs, and the plan/apply workflow)
- Experience deploying at least a few resources to a cloud provider (AWS, Azure, or GCP) using Terraform
- Familiarity with version control workflows (branching, pull requests, code review) and basic CI/CD concepts
- A Terraform installation (v1.0+) and access to a cloud provider account for hands-on practice

## Key Takeaways

1. **Module composition over monoliths** - Break infrastructure into small, focused modules with clear input/output contracts rather than defining everything in a single root configuration. This enables reuse, independent testing, and team-level ownership of infrastructure components.
2. **Remote state with locking is non-negotiable** - Store state in a shared backend (S3 + DynamoDB, Terraform Cloud, or GCS) with state locking enabled from day one. Local state files create collaboration bottlenecks and risk data loss or corruption from concurrent applies.
3. **Pin versions explicitly** - Lock provider versions, module versions, and the Terraform version itself using version constraints. Unpinned dependencies lead to non-reproducible plans and unexpected breaking changes during routine applies.
4. **Shift security left with static analysis** - Integrate tfsec, Checkov, or similar tools into your CI pipeline to catch security misconfigurations (open security groups, unencrypted storage, overly permissive IAM) before they reach any environment.
5. **Validate inputs at the boundary** - Use variable validation blocks and custom conditions to reject invalid configurations early with clear error messages, rather than discovering failures mid-apply or after deployment.

## How to Use

### Step 1: Organize Code with a Standard Directory Structure

Adopt a consistent layout that separates reusable modules from environment-specific configurations:

1. Create a `modules/` directory for reusable components, each with its own `main.tf`, `variables.tf`, `outputs.tf`, and `README.md`
2. Create environment directories (`environments/dev/`, `environments/staging/`, `environments/prod/`) that call modules with environment-specific variable values
3. Keep root modules thin — they should compose modules and pass variables, not define resources directly
4. Use `terraform.tfvars` or `.tfvars` files per environment rather than hardcoding values
5. Run `terraform fmt -recursive` on every save or as a pre-commit hook to enforce consistent formatting per the HashiCorp style guide

### Step 2: Configure Remote State and Workspaces

Set up shared state management before writing any production infrastructure:

1. Create a state backend (e.g., an S3 bucket with versioning enabled and a DynamoDB table for locking) — provision this manually or with a minimal bootstrap configuration
2. Configure the backend block in each root module, using a unique key per stack (e.g., `key = "environments/dev/networking.tfstate"`)
3. Enable state locking to prevent concurrent modifications — this is automatic with S3+DynamoDB, Terraform Cloud, and most other backends
4. Evaluate workspace strategies: separate state files per environment (recommended for most teams) versus Terraform workspaces (suitable for identical infrastructure with minor variable differences)
5. Never store state locally for shared infrastructure — add `*.tfstate` and `*.tfstate.backup` to `.gitignore`

### Step 3: Enforce Version Constraints and Variable Validation

Lock down dependencies and validate inputs to make configurations reproducible and safe:

1. Add a `required_providers` block with explicit version constraints (e.g., `version = "~> 5.0"` for the AWS provider) and set `required_version` for Terraform itself
2. Pin module sources to specific versions or Git tags (`source = "git::https://...?ref=v1.2.0"`) — never reference `main` or `HEAD` in production
3. Add `validation` blocks to variables that have constraints: CIDR ranges, naming patterns, allowed instance types, or enum-like values
4. Use `precondition` and `postcondition` blocks in resources and data sources to assert invariants that Terraform cannot check statically
5. Generate a `.terraform.lock.hcl` file and commit it to version control so all team members use identical provider builds

### Step 4: Integrate Security Scanning into CI/CD

Catch misconfigurations before they become deployed vulnerabilities:

1. Add tfsec to your CI pipeline — it runs against HCL files directly and flags issues like unencrypted S3 buckets, public security group rules, and missing logging configurations
2. Add Checkov as a complementary scanner — it covers Terraform, CloudFormation, and Kubernetes manifests with over 1,000 built-in policies
3. Configure scanning to run on every pull request and block merges on high-severity findings
4. Suppress false positives with inline comments (e.g., `#tfsec:ignore:aws-s3-enable-versioning`) accompanied by a justification
5. Periodically review and update scanner versions to pick up new policy rules as cloud providers add features and new CVEs are discovered

### Step 5: Build a Terraform CI/CD Pipeline

Automate the plan/apply workflow to eliminate manual errors and enforce review gates:

1. On pull request: run `terraform fmt -check`, `terraform validate`, tfsec/Checkov scans, and `terraform plan` — post the plan output as a PR comment for reviewers
2. Require at least one approval on the plan output before any apply can proceed
3. On merge to main: run `terraform apply` with the saved plan file from the reviewed PR, or re-plan and auto-apply if your workflow supports it
4. Use separate CI credentials per environment with least-privilege IAM roles — the dev pipeline should not have production permissions
5. Store sensitive variables (API keys, secrets) in your CI platform's secret management or a vault, never in `.tfvars` files committed to version control

## Practice Notes

- Convert reading into decisions. Pull out three recommendations, rate whether your current or sample workload follows them, and write the gap as an actionable backlog item.
- Translate the lesson into an IaC operating habit: repeatable plans, state safety, reviewable diffs, module boundaries, policy checks, and cleanup of any billable resources.
- Completion checkpoint: you can adapt the pattern to a second environment, identify its tradeoffs, and explain the operational risks it introduces.
- Portfolio artifact: create a short note titled "Terraform Best Practices - applied takeaway" with the scenario you used, the decision you made, and one follow-up task you would assign to yourself or a team.

## Deliverable

Write a Terraform style and operations review for a small root module:

- Directory structure assessment against the module/environment pattern
- State strategy note covering backend, locking, encryption, and state file ownership
- Version pinning review for Terraform, providers, modules, and `.terraform.lock.hcl`
- Security scan summary with high-severity findings and justified suppressions
- CI gate proposal listing commands that must pass before merge

## Validation

Use this local CI gate for the sample module:

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform plan -lock=false -out=style-review.plan
tflint --init
tflint --recursive
checkov -d .
```

The concrete outputs are the style review, state strategy note, and saved plan summary. A reviewer should be able to identify whether the module is ready for shared state and automated deployment.

## Self-Assessment

- Which convention most reduces future review effort?
- What state failure mode is still possible after your backend choice?
- Which validation belongs locally, in CI, and before production apply?
- What policy would you enforce automatically instead of relying on human review?

## Related Resources

- [Terraform Style Guide](https://developer.hashicorp.com/terraform/language/style) - HashiCorp's official conventions for code formatting, naming, and file organization
- [Terraform Backend Configuration](https://developer.hashicorp.com/terraform/language/backend) - Documentation on configuring remote state backends including S3, GCS, and Terraform Cloud
- [tfsec - Security Scanner for Terraform](https://aquasecurity.github.io/tfsec/) - Static analysis tool that detects potential security issues in Terraform configurations
- [Checkov - Policy-as-Code Scanner](https://www.checkov.io/) - Open-source static analysis tool for infrastructure-as-code with 1,000+ built-in policies

## Estimated Time

- **Reading the Terraform style guide and organizing a sample project**: 15 minutes
- **Configuring remote state backend with locking**: 10 minutes
- **Adding version constraints and variable validation to an existing module**: 10 minutes
- **Running tfsec and Checkov against your configurations and triaging findings**: 10 minutes
- **Total for this lesson**: ~45 minutes
