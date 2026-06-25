# Migration Guide: Terraform to OpenTofu with State Encryption

This guide walks through migrating the lab project from Terraform to OpenTofu, then enabling client-side state encryption.

## Background

OpenTofu is a drop-in replacement for Terraform 1.5.x. The CLI commands, configuration language (HCL), state format, and provider ecosystem are compatible. Migration for most projects is a matter of swapping the binary and re-initializing.

Key differences relevant to this migration:

| Aspect | Terraform | OpenTofu |
|--------|-----------|----------|
| CLI binary | `terraform` | `tofu` |
| Registry | registry.terraform.io | registry.opentofu.org (also accepts terraform registry sources) |
| Lock file | `.terraform.lock.hcl` | `.terraform.lock.hcl` (same format) |
| State format | JSON | JSON (identical, read/write compatible) |
| State encryption | Not supported natively | Built-in client-side encryption |
| License | BSL 1.1 | MPL 2.0 |

---

## Step 1: Verify Current Terraform State

Before migrating, confirm your project is in a clean state.

```bash
terraform init
terraform validate
terraform plan
```

If you have previously applied this configuration, `terraform plan` should show no changes. If you are starting fresh, that is fine too — the migration works regardless of whether state exists.

Record your Terraform version for reference:

```bash
terraform version
```

---

## Step 2: Remove Terraform Initialization Artifacts

The `.terraform` directory contains downloaded providers and module caches specific to the Terraform binary. OpenTofu will recreate these on `tofu init`.

```bash
rm -rf .terraform
rm -f .terraform.lock.hcl
```

The state file (`terraform.tfstate`) is NOT deleted. OpenTofu reads the same state format.

---

## Step 3: Initialize with OpenTofu

Run the OpenTofu initialization:

```bash
tofu init
```

You should see output similar to:

```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.x.x...

OpenTofu has been successfully initialized!
```

OpenTofu resolves `registry.terraform.io/hashicorp/aws` transparently — no source address changes are required. The provider binary is compatible between Terraform and OpenTofu.

---

## Step 4: Validate and Plan

Confirm the configuration is valid under OpenTofu:

```bash
tofu validate
```

Then run a plan to confirm there is no diff against existing state:

```bash
tofu plan
```

**Expected output (if state exists):** "No changes. Your infrastructure matches the configuration."

**Expected output (if no state):** A plan showing all resources to be created — same as what Terraform would show.

At this point, migration is complete. You can use `tofu apply`, `tofu destroy`, and all other commands exactly as you would with Terraform.

---

## Step 5: Enable State Encryption (PBKDF2 + AES-GCM)

OpenTofu supports encrypting state files at rest. This protects sensitive values (database passwords, API keys, private IPs) that Terraform stores in plaintext JSON.

### 5a: Add a passphrase variable

Add the following to `variables.tf`:

```hcl
variable "state_passphrase" {
  description = "Passphrase for state file encryption (supply via TF_VAR_state_passphrase)"
  type        = string
  sensitive   = true
}
```

### 5b: Add the encryption block

Add the following inside the `terraform {}` block in `versions.tf`:

```hcl
terraform {
  encryption {
    key_provider "pbkdf2" "state_key" {
      passphrase = var.state_passphrase
    }

    method "aes_gcm" "encrypt" {
      keys = key_provider.pbkdf2.state_key
    }

    state {
      method = method.aes_gcm.encrypt
    }

    plan {
      method = method.aes_gcm.encrypt
    }
  }
}
```

Your complete `versions.tf` should look like:

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "registry.terraform.io/hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }

  encryption {
    key_provider "pbkdf2" "state_key" {
      passphrase = var.state_passphrase
    }

    method "aes_gcm" "encrypt" {
      keys = key_provider.pbkdf2.state_key
    }

    state {
      method = method.aes_gcm.encrypt
    }

    plan {
      method = method.aes_gcm.encrypt
    }
  }
}
```

### 5c: Set the passphrase

Supply the passphrase as an environment variable (never commit it to version control):

```bash
export TF_VAR_state_passphrase="a-strong-passphrase-at-least-16-chars"
```

### 5d: Apply to encrypt state

Re-initialize and apply:

```bash
tofu init
tofu apply
```

On the next apply (or `tofu refresh`), OpenTofu encrypts the state file using AES-256-GCM with a key derived from your passphrase via PBKDF2.

### 5e: Verify encryption

Inspect the state file:

```bash
cat terraform.tfstate
```

Instead of readable JSON, you should see a structure like:

```json
{
  "serial": 1,
  "lineage": "...",
  "encryption": {
    "key_provider": "pbkdf2",
    "method": "aes_gcm",
    ...
  },
  "encrypted_data": "base64-encoded-ciphertext..."
}
```

The resource attributes, outputs, and sensitive values are no longer visible in plaintext.

### 5f: Confirm operations still work

With the passphrase set, all commands work normally:

```bash
export TF_VAR_state_passphrase="a-strong-passphrase-at-least-16-chars"
tofu plan    # Decrypts state, compares, shows plan
tofu output  # Decrypts state, displays outputs
```

Without the passphrase, OpenTofu refuses to read the state:

```bash
unset TF_VAR_state_passphrase
tofu plan    # Error: encryption passphrase required
```

---

## Step 6: (Bonus) AWS KMS Key Provider

For production environments, replace the passphrase with AWS KMS. This eliminates the need to manage and distribute a shared secret — access is controlled via IAM policies.

### 6a: Create a KMS key

```bash
aws kms create-key \
  --description "OpenTofu state encryption key" \
  --tags TagKey=Project,TagValue=opentofu-lab \
  --query 'KeyMetadata.KeyId' \
  --output text
```

Save the returned key ID.

### 6b: Replace the encryption block

```hcl
terraform {
  encryption {
    key_provider "aws_kms" "state_key" {
      kms_key_id = "arn:aws:kms:us-east-1:ACCOUNT_ID:key/KEY_ID"
      region     = "us-east-1"
      key_spec   = "AES_256"
    }

    method "aes_gcm" "encrypt" {
      keys = key_provider.aws_kms.state_key
    }

    state {
      method = method.aes_gcm.encrypt
    }

    plan {
      method = method.aes_gcm.encrypt
    }
  }
}
```

### 6c: Handle migration from PBKDF2 to KMS

If you already have state encrypted with the passphrase, use a `fallback` block to decrypt old state while encrypting new state with KMS:

```hcl
terraform {
  encryption {
    key_provider "pbkdf2" "old_key" {
      passphrase = var.state_passphrase
    }

    key_provider "aws_kms" "new_key" {
      kms_key_id = "arn:aws:kms:us-east-1:ACCOUNT_ID:key/KEY_ID"
      region     = "us-east-1"
      key_spec   = "AES_256"
    }

    method "aes_gcm" "old_method" {
      keys = key_provider.pbkdf2.old_key
    }

    method "aes_gcm" "new_method" {
      keys = key_provider.aws_kms.new_key
    }

    state {
      method = method.aes_gcm.new_method

      fallback {
        method = method.aes_gcm.old_method
      }
    }

    plan {
      method = method.aes_gcm.new_method

      fallback {
        method = method.aes_gcm.old_method
      }
    }
  }
}
```

Run `tofu apply` once with both keys available. After that, remove the `fallback` and `old_key` blocks — the state is now fully encrypted with KMS.

### 6d: IAM policy for the KMS key

Any identity running `tofu` commands needs these KMS permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:GenerateDataKey",
        "kms:Decrypt"
      ],
      "Resource": "arn:aws:kms:us-east-1:ACCOUNT_ID:key/KEY_ID"
    }
  ]
}
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `tofu init` fails to find provider | Ensure you have internet access; OpenTofu downloads from its own CDN mirrors |
| Plan shows unexpected changes after migration | Check Terraform version — OpenTofu is compatible with 1.5.x; features from 1.6+ may not be supported |
| State encryption error on plan | Verify `TF_VAR_state_passphrase` is set in your shell environment |
| Cannot read state after enabling encryption | The passphrase must match exactly; there is no recovery without it |
| KMS access denied | Verify IAM policy grants `kms:GenerateDataKey` and `kms:Decrypt` on the key ARN |

---

## Summary

| Step | Action | Verification |
|------|--------|--------------|
| 1 | Validate existing Terraform project | `terraform plan` shows no errors |
| 2 | Remove `.terraform/` and lock file | Directory deleted |
| 3 | Run `tofu init` | Providers download successfully |
| 4 | Run `tofu plan` | No unexpected changes |
| 5 | Add encryption block + passphrase | State file is encrypted ciphertext |
| 6 | (Bonus) Switch to AWS KMS | State encrypted without shared passphrase |

You have successfully migrated from Terraform to OpenTofu and secured your state file with client-side encryption.
