# Lab: Migrate a Terraform Project to OpenTofu

## Objective

You have a working Terraform project that deploys a small AWS stack (VPC, subnet, security group, EC2 instance, and S3 bucket). Your task is to migrate this project from Terraform to OpenTofu and then enable client-side state encryption — a feature unique to OpenTofu.

By the end of this lab you will have:

1. Verified the existing Terraform configuration is valid
2. Replaced the `terraform` CLI with the `tofu` CLI
3. Confirmed zero-diff migration (no infrastructure changes)
4. Enabled AES-GCM state encryption using PBKDF2 key derivation
5. Verified that `terraform.tfstate` is encrypted and unreadable without the passphrase

## Prerequisites

- OpenTofu installed (`brew install opentofu` or see [install docs](https://opentofu.org/docs/intro/install/))
- Terraform >= 1.5.0 installed (for the "before" comparison)
- AWS CLI configured with credentials that can create VPC, EC2, and S3 resources
- A text editor

## Project Structure

```
lab/
├── README.md                  # This file
├── main.tf                    # AWS resources (VPC, subnet, SG, EC2, S3)
├── variables.tf               # Input variable declarations
├── outputs.tf                 # Output values
├── versions.tf                # Terraform/provider version constraints
├── terraform.tfvars.example   # Example variable values
└── migration-guide.md         # Step-by-step migration instructions
```

## Instructions

### Part 1: Understand the Existing Project

1. Read through `main.tf` to understand what resources are declared
2. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your values:

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Update `ami_id` to a valid AMI for your region (Amazon Linux 2023 recommended)
4. Set `bucket_suffix` to something globally unique
5. Initialize and validate with Terraform:

   ```bash
   terraform init
   terraform validate
   terraform plan
   ```

### Part 2: Migrate to OpenTofu

Follow the detailed instructions in `migration-guide.md` to:

1. Remove the `.terraform` directory and lock file
2. Re-initialize with `tofu init`
3. Run `tofu plan` and confirm no changes are detected
4. (Optional) Apply the infrastructure with `tofu apply`

### Part 3: Enable State Encryption

Continue with the state encryption section in `migration-guide.md` to:

1. Add the `encryption` block to your configuration
2. Supply a passphrase via environment variable
3. Run `tofu apply` to re-encrypt the state
4. Inspect the state file to confirm encryption

### Part 4: (Bonus) AWS KMS Key Provider

Replace the passphrase-based key derivation with AWS KMS for production-grade key management. Instructions are in the final section of `migration-guide.md`.

## Success Criteria

- `tofu validate` passes without errors
- `tofu plan` shows no changes (if infrastructure was previously applied with Terraform)
- `terraform.tfstate` contents are encrypted (not readable JSON)
- You can still run `tofu plan` successfully with the encryption passphrase set

## Tips

- If you have existing Terraform state, OpenTofu reads it directly — no state conversion needed
- The `registry.terraform.io` provider source works with OpenTofu (it redirects transparently)
- State encryption is applied on the next `tofu apply` or `tofu refresh` after adding the encryption block
- Keep your passphrase safe — losing it means losing access to your state file

## Cleanup

If you applied real infrastructure, destroy it when done:

```bash
export TF_VAR_state_passphrase="your-passphrase-here"
tofu destroy
```
