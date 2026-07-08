---
title: "Building Immutable AMIs with Packer"
type: lab
difficulty: intermediate
tier: free
tags: ["packer", "ami", "immutable-infrastructure", "aws"]
---

# Building Immutable AMIs with Packer

## Overview

Immutable infrastructure is a deployment paradigm in which servers are never modified after they are deployed. If something needs to be updated, fixed, or changed in any way, new servers are built from a common image with the appropriate changes and provisioned to replace the old ones. Once the new servers are validated, they are put into service and the old ones are decommissioned. There is no SSH-in-and-patch-it workflow — configuration drift is eliminated because every running instance traces back to a single, versioned image build.

Packer is HashiCorp's open-source tool for building that image. It reads a declarative template, launches a temporary build instance from a source image, runs provisioners against it (shell scripts, configuration management tools, file uploads), and then captures the result as a new machine image — in this lesson, an Amazon Machine Image (AMI). The same template can target multiple platforms (AWS, Azure, GCP, Docker, VMware) from a single source configuration, but this lesson focuses on the AWS `amazon-ebs` builder, which is the most common entry point.

This lab builds a real AMI with nginx baked in, using Packer's current HCL2 template format (the legacy JSON template format is deprecated). You will install Packer, initialize the AWS plugin, format and validate the template, run a real build against your AWS account, launch an instance from the resulting AMI to prove nginx is running out of the box, and then tear everything down. The core lesson is architectural, not syntactic: once this AMI exists, it is never patched in place. A configuration change means a new template run, a new AMI, and an instance replacement — not a `sudo apt upgrade` on a live box.

## Prerequisites

- An AWS account with permissions to launch EC2 instances, create AMIs, and create/delete EBS snapshots (a sandbox or personal account is recommended)
- AWS CLI installed and configured with credentials (`aws configure`) that Packer's AWS plugin can use
- Command-line proficiency on Linux, macOS, or WSL
- Basic familiarity with EC2 concepts (AMIs, instance types, security groups, key pairs)
- Willingness to incur a small, short-lived AWS cost — this lab provisions a real billable AMI, EBS snapshot, and EC2 instance (see Cleanup)

## Key Takeaways

1. **Immutable infrastructure replaces, it doesn't patch** - Once an AMI is validated and in use, configuration changes are made by building a new AMI and replacing running instances, not by modifying servers in place.
2. **Packer separates image building from image use** - A Packer template describes how to build an image once; the resulting AMI can then be launched by Terraform, Auto Scaling Groups, or manually, decoupling the build pipeline from the deployment mechanism.
3. **HCL2 is the current Packer format, not JSON** - Modern Packer templates use `.pkr.hcl` files with `packer`, `source`, and `build` blocks. The legacy JSON template format still works but is deprecated for new projects.
4. **Source AMI and provisioner commands must match** - A `source_ami_filter` that selects an Amazon Linux AMI and a provisioner that runs `apt` commands will fail, because Amazon Linux uses `yum`/`dnf`. Pick one distribution and stay consistent through the whole template.
5. **Every build artifact has cleanup obligations** - A successful `packer build` leaves behind a billable AMI and an underlying EBS snapshot that persist until you explicitly deregister and delete them.

## How to Use

### Step 1: Install Packer

1. **macOS (Homebrew)**:
   ```bash
   brew tap hashicorp/tap
   brew install hashicorp/tap/packer
   ```
2. **Linux (Debian/Ubuntu)**:
   ```bash
   wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
   echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
   sudo apt-get update && sudo apt-get install packer
   ```
3. **Linux (RPM-based)**:
   ```bash
   sudo dnf install -y dnf-plugins-core
   sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
   sudo dnf install packer
   ```
4. Verify the installation:
   ```bash
   packer --version
   ```

### Step 2: Review the Lab Template

1. Open `lab/immutable-ami.pkr.hcl` and `lab/variables.pkr.hcl` in this lesson directory
2. Note the `packer { required_plugins { ... } }` block — this pins the `amazon` plugin so builds are reproducible
3. Note the `source "amazon-ebs" "app"` block — it filters for the most recent Ubuntu 22.04 LTS AMI published by Canonical (owner `099720109477`), not a hard-coded AMI ID that will go stale
4. Note the `ami_name` uses `${local.timestamp}`, derived from a `locals` block calling `timestamp()` — every build produces a uniquely named AMI so repeated builds never collide
5. Note the `build` block's `provisioner "shell"` runs `apt-get` commands, matching the Ubuntu source image — Amazon Linux and `apt` do not mix

### Step 3: Initialize and Validate

1. From this lesson's root directory, initialize the plugins the template requires:
   ```bash
   packer init lab/
   ```
2. Format the template (fixes indentation and spacing in place):
   ```bash
   packer fmt lab/
   ```
3. Validate the template's syntax and configuration:
   ```bash
   packer validate lab/
   ```
4. Confirm the output reads `The configuration is valid.` before proceeding

### Step 4: Build the AMI

1. Run the build, overriding variables if you want a non-default region or instance type:
   ```bash
   packer build -var region=us-east-1 -var instance_type=t3.micro lab/immutable-ami.pkr.hcl
   ```
2. Watch the build log: Packer launches a temporary EC2 instance, waits for SSH, runs the shell provisioner (`apt-get update`, `apt-get install -y nginx`), stops the instance, and creates an AMI from its root volume
3. Note the AMI ID printed at the end of the build (`ami-xxxxxxxxxxxxxxxxx`) — you will need it for the next step and for cleanup
4. Confirm the temporary build instance was terminated automatically (Packer does this by default) by checking the EC2 console or `aws ec2 describe-instances`

### Step 5: Launch and Verify

1. Launch a new EC2 instance from the AMI you just built, in a security group that allows inbound HTTP (port 80) from your IP:
   ```bash
   aws ec2 run-instances \
     --image-id ami-xxxxxxxxxxxxxxxxx \
     --instance-type t3.micro \
     --security-group-ids sg-xxxxxxxx \
     --subnet-id subnet-xxxxxxxx \
     --count 1
   ```
2. Once the instance is running, note its public IP and confirm nginx is already serving traffic, with no manual setup step:
   ```bash
   curl http://<instance-public-ip>
   ```
3. Confirm the response is the default nginx welcome page
4. This is the immutability payoff: the instance never ran `apt-get install nginx` itself — it booted from an image that already had nginx baked in. If nginx needs a version bump or a config change, the fix is a new `packer build`, a new AMI, and a new instance to replace this one — not an in-place edit on this box.

## Practice Notes

- Run hands-on work in a sandbox and keep a short lab log with commands, screenshots or outputs, resources created, cleanup steps, and the one pattern you would reuse in production.
- Translate the lesson into an IaC operating habit: repeatable plans, state safety, reviewable diffs, module boundaries, policy checks, and cleanup of any billable resources.
- Completion checkpoint: you can adapt the pattern to a second environment, identify its tradeoffs, and explain the operational risks it introduces.
- Portfolio artifact: create a short note titled "Building Immutable AMIs with Packer - applied takeaway" with the scenario you used, the decision you made, and one follow-up task you would assign to yourself or a team.

## Deliverable

Produce a short AMI build record for this lab:

- The AMI ID, source AMI filter, and Packer plugin version used for the build
- The full `packer build` log or a summary of each build stage (source image resolution, provisioning, image creation)
- The verification result: the `curl` output (or screenshot) proving nginx responds on the launched instance
- A cleanup confirmation listing the deregistered AMI ID, deleted snapshot ID, and terminated instance ID

## Validation

Run these checks before marking the lesson complete:

```bash
packer fmt -check -diff lab/
packer validate lab/
packer build lab/immutable-ami.pkr.hcl
curl http://<instance-public-ip>
```

`packer fmt -check` should report no formatting diffs, `packer validate` should report the configuration is valid, `packer build` should complete and print a new AMI ID, and the `curl` request against an instance launched from that AMI should return the default nginx welcome page without any manual provisioning step.

## Cleanup

This lab creates real, billable AWS resources: an AMI, its backing EBS snapshot, and (if you completed Step 5) a running EC2 instance. None of these are covered by a "set and forget" free tier guarantee — clean them up in this order as soon as you finish verifying:

```bash
# 1. Terminate any test instance launched from the AMI
aws ec2 terminate-instances --instance-ids i-xxxxxxxxxxxxxxxxx

# 2. Deregister the AMI itself
aws ec2 deregister-image --image-id ami-xxxxxxxxxxxxxxxxx

# 3. Delete the EBS snapshot backing the AMI (deregistering the AMI does not delete the snapshot)
aws ec2 delete-snapshot --snapshot-id snap-xxxxxxxxxxxxxxxxx
```

Find the snapshot ID from the AMI's block device mapping before deregistering it — once the AMI is deregistered, the snapshot is easy to lose track of:

```bash
aws ec2 describe-images --image-ids ami-xxxxxxxxxxxxxxxxx --query 'Images[0].BlockDeviceMappings[0].Ebs.SnapshotId'
```

Confirm no orphaned AMIs, snapshots, or instances remain by checking the EC2 console or `aws ec2 describe-images --owners self` the next day, and check Cost Explorer for any unexpected EBS or EC2 charges.

## Self-Assessment

- What would break if the `source_ami_filter` matched an Amazon Linux AMI but the provisioner still ran `apt-get` commands?
- Why does the `ami_name` need a timestamp or other unique suffix instead of a fixed string?
- If nginx needed a security patch tomorrow, what is the correct sequence of steps under an immutable infrastructure model — and what would be the wrong way to do it?
- What evidence would prove to a reviewer that every billable resource from this lab was fully cleaned up?

## Related Resources

- [Packer Documentation](https://developer.hashicorp.com/packer/docs) - Official reference for HCL2 template syntax, builders, provisioners, and plugins
- [Amazon EBS Builder Reference](https://developer.hashicorp.com/packer/integrations/hashicorp/amazon/latest/components/builder/ebs) - Full configuration options for the `amazon-ebs` source used in this lab
- [Packer HCL2 Getting Started Tutorial](https://developer.hashicorp.com/packer/tutorials/docker-get-started/get-started-install-cli) - HashiCorp's own walkthrough of installing Packer and building a first HCL2 template
- [Immutable Infrastructure (Wikipedia)](https://en.wikipedia.org/wiki/Immutable_infrastructure) - Background on the immutable infrastructure paradigm this lab demonstrates

## Estimated Time

- **Installation and template review**: 10 minutes
- **Initialize, format, and validate**: 5 minutes
- **AMI build**: 10-15 minutes (most of this is Packer waiting on instance boot and AMI creation)
- **Launch and verification**: 10 minutes
- **Cleanup**: 10 minutes
- **Total for this lesson**: ~50-60 minutes
