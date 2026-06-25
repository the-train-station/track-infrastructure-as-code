# Lab: Terraform Best Practices Refactoring Exercise

## Overview

You've inherited a Terraform project from a colleague who left the company. The infrastructure works, but the code is a maintenance nightmare. Your task is to refactor it into a well-structured, secure, and maintainable configuration following Terraform best practices.

## The Scenario

The file `main.tf` contains the entire infrastructure for a web application: networking, compute, database, storage, and IAM -- all crammed into a single file with hardcoded values, duplicated blocks, and security issues.

Your goal is to refactor this into a modular, production-ready Terraform project.

## Anti-Patterns to Find and Fix

Work through the following categories. Each represents a real-world best practice violation.

### 1. No Module Structure

**Problem:** All resources live in a single `main.tf` file (~350 lines).

**Why it matters:** Monolithic configs are hard to test, reuse, and reason about. Teams can't work on networking independently of compute. Changes to one resource risk unintended side effects on others.

**Fix:** Extract logical groupings into modules (`networking`, `compute`, `database`). Each module should have a clear interface (`variables.tf`, `outputs.tf`) and a single responsibility.

### 2. No Provider Version Pinning

**Problem:** The AWS provider has no version constraint. The `required_version` for Terraform itself is missing.

**Why it matters:** Without pinning, `terraform init` grabs the latest provider version, which may contain breaking changes. Your infrastructure becomes non-reproducible -- what works today may fail tomorrow.

**Fix:** Pin both the Terraform version and provider versions with pessimistic constraints (e.g., `~> 5.0`).

### 3. Hardcoded Values Everywhere

**Problem:** Region, AMI IDs, CIDR blocks, instance types, and key pair names are all hardcoded directly in resource blocks.

**Why it matters:** You can't reuse this code for a staging environment without copy-pasting the entire file. Every environment-specific change requires editing resource definitions.

**Fix:** Extract configurable values into `variables.tf` with descriptions, types, defaults where appropriate, and validation blocks for inputs that have constraints.

### 4. No Remote Backend

**Problem:** No backend configuration exists -- state is stored locally.

**Why it matters:** Local state can't be shared between team members. There's no locking, so concurrent applies can corrupt state. If the laptop dies, the state is gone.

**Fix:** Configure an S3 backend with DynamoDB locking.

### 5. Duplicated Resources

**Problem:** Three nearly identical EC2 instances are defined as separate resource blocks (`web1`, `web2`, `web3`).

**Why it matters:** Adding a fourth server means copying 25 lines and updating values by hand. Forgetting to update one field creates drift between instances that should be identical.

**Fix:** Use `for_each` or `count` to define instances from a single resource block with a variable controlling the count and per-instance configuration.

### 6. Security Issues

**Problem:** Multiple security violations exist:

- SSH (port 22) open to `0.0.0.0/0`
- Database password hardcoded in plain text
- S3 bucket has no encryption
- S3 bucket policy allows public read access to all objects
- IAM policy uses wildcard (`*`) actions and resources
- RDS has no backup retention and no multi-AZ
- No public access block on S3 bucket

**Why it matters:** These are the kind of issues that lead to data breaches, compliance failures, and AWS account compromises.

**Fix:** Restrict SSH to known CIDRs (or remove it in favor of SSM), use `sensitive` variables or Secrets Manager for the DB password, enable S3 encryption and public access blocks, scope IAM policies to least privilege, enable RDS backups and multi-AZ.

### 7. Inconsistent Naming and Tagging

**Problem:** Tags vary wildly:

- `Environment` vs `Env` vs no environment tag
- `Team` vs `team` (case inconsistency)
- Subnet names: `public-1`, `public-2`, `private-1`, `priv-subnet-2`
- Instance names: `web-server-1`, `web-server-2`, `WebServer3`

**Why it matters:** Inconsistent tags break cost allocation, make resources hard to find, and prevent automated tooling from working correctly.

**Fix:** Define a consistent tagging strategy using `default_tags` in the provider block or a local variable merged into every resource.

### 8. No Lifecycle Management

**Problem:** S3 bucket has no versioning, no lifecycle rules. CloudWatch log groups have no retention period. RDS has no backups.

**Why it matters:** Without retention policies, storage costs grow unbounded. Without versioning, accidental deletions are permanent.

**Fix:** Enable versioning, set lifecycle rules for old versions, set log retention periods, enable RDS automated backups.

## Your Task

Refactor the `main.tf` into the following structure:

```
solution/
  main.tf              # Root module - composes child modules
  variables.tf         # Input variables with validation
  outputs.tf           # Root-level outputs
  versions.tf          # Terraform and provider version constraints
  backend.tf           # Remote state configuration
  modules/
    networking/
      main.tf          # VPC, subnets, IGW, route tables, security groups
      variables.tf
      outputs.tf
    compute/
      main.tf          # EC2 instances using for_each
      variables.tf
      outputs.tf
    database/
      main.tf          # RDS with proper security settings
      variables.tf
      outputs.tf
```

## Checklist

Use this checklist to verify your refactoring is complete:

- [ ] Terraform and provider versions pinned in `versions.tf`
- [ ] Remote backend configured with S3 + DynamoDB locking
- [ ] All hardcoded values extracted to variables
- [ ] Variables have descriptions, types, and validation where needed
- [ ] Resources organized into modules with clear boundaries
- [ ] EC2 instances use `for_each` instead of copy-paste
- [ ] SSH restricted to a specific CIDR variable (not 0.0.0.0/0)
- [ ] Database password marked as `sensitive` (not hardcoded)
- [ ] S3 bucket has encryption enabled
- [ ] S3 public access block configured
- [ ] IAM policies scoped to least privilege
- [ ] Consistent tagging strategy via `default_tags` or locals
- [ ] CloudWatch log groups have retention periods set
- [ ] RDS has backup retention and multi-AZ enabled
- [ ] Outputs are meaningful and documented
- [ ] No secrets in plain text anywhere in the code

## Hints

- Start by identifying the module boundaries: what resources naturally group together?
- Think about what each module needs as input (variables) and what it exposes (outputs).
- The root module's job is to wire modules together -- module A's output becomes module B's input.
- Use `terraform fmt` and `terraform validate` as you go.

## Reference Solution

A complete reference solution is available in the `solution/` directory. Try to complete the exercise yourself first, then compare your approach with the reference.
