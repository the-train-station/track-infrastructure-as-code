# Lab: Module Composition with terraform-aws-modules

## Objective

Build a complete web server environment by composing three community modules from [terraform-aws-modules](https://github.com/terraform-aws-modules). You will wire together a VPC, Security Group, and EC2 instance, passing outputs from one module as inputs to the next. This is the core pattern for building real infrastructure with Terraform: small, tested building blocks connected through explicit data flow.

## What You Will Learn

- How to declare and configure community modules from the Terraform Registry
- How output chaining creates an implicit dependency graph between modules
- How to read module documentation to discover available inputs and outputs
- How module composition replaces hundreds of lines of raw resource configuration

## Prerequisites

- Terraform CLI >= 1.5.0 installed
- AWS credentials configured (`aws configure` or environment variables)
- An EC2 key pair in your target region (optional, for SSH access)
- Familiarity with VPC concepts (subnets, route tables, security groups)

## Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│  module "vpc" (terraform-aws-modules/vpc/aws ~> 5.0)                 │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │  VPC: 10.0.0.0/16                                               │ │
│  │                                                                  │ │
│  │  ┌──────────────────┐  ┌──────────────────┐                     │ │
│  │  │ Public Subnet    │  │ Public Subnet    │                     │ │
│  │  │ 10.0.1.0/24      │  │ 10.0.2.0/24      │                     │ │
│  │  │ us-east-1a       │  │ us-east-1b       │                     │ │
│  │  └──────────────────┘  └──────────────────┘                     │ │
│  │                                                                  │ │
│  │  ┌──────────────────┐  ┌──────────────────┐                     │ │
│  │  │ Private Subnet   │  │ Private Subnet   │                     │ │
│  │  │ 10.0.101.0/24    │  │ 10.0.102.0/24    │                     │ │
│  │  │ us-east-1a       │  │ us-east-1b       │                     │ │
│  │  └──────────────────┘  └──────────────────┘                     │ │
│  └─────────────────────────────────────────────────────────────────┘ │
└──────────────────────┬───────────────────────────────────────────────┘
                       │
         ┌─────────────┼─────────────┐
         │ vpc_id      │ public_subnets[0]
         ▼             │             ▼
┌─────────────────┐    │   ┌──────────────────────────────────────────┐
│ module "web_sg" │    │   │ module "ec2"                             │
│ (security-group │    │   │ (ec2-instance/aws ~> 5.0)                │
│  /aws ~> 5.0)   │    │   │                                          │
│                 │    │   │  subnet_id = module.vpc.public_subnets[0]│
│  vpc_id =      │    │   │  vpc_security_group_ids =                │
│  module.vpc.   │    │   │    [module.web_sg.security_group_id]     │
│  vpc_id        │    │   │                                          │
│                 │    │   └──────────────────────────────────────────┘
│  Rules:         │    │             ▲
│   HTTP  :80     │    │             │
│   HTTPS :443    │────┘             │
│   SSH   :22     │                  │
└────────┬────────┘                  │
         │ security_group_id         │
         └───────────────────────────┘
```

## The Dependency Graph

Terraform modules create implicit dependencies through references. In this lab:

1. **VPC must be created first** -- it produces `vpc_id` and `public_subnets`
2. **Security Group depends on VPC** -- it needs `module.vpc.vpc_id` to know which VPC to attach to
3. **EC2 depends on both VPC and SG** -- it needs `module.vpc.public_subnets[0]` for placement and `module.web_sg.security_group_id` for network rules

Terraform resolves this automatically. You never write `depends_on` for module output chaining -- the reference itself creates the dependency.

## Instructions

### Step 1: Review the Configuration

Read through each file to understand the structure:

| File | Purpose |
|------|---------|
| `versions.tf` | Terraform and provider version constraints |
| `variables.tf` | All input variables with types and defaults |
| `main.tf` | The three module blocks and their wiring |
| `outputs.tf` | Values exposed from each module |
| `terraform.tfvars.example` | Example variable values |

### Step 2: Understand Output Chaining

Open `main.tf` and trace the data flow:

```hcl
# VPC output -> SG input
module "web_sg" {
  vpc_id = module.vpc.vpc_id  # <-- output from vpc module
}

# VPC output -> EC2 input
module "ec2" {
  subnet_id = module.vpc.public_subnets[0]  # <-- output from vpc module
}

# SG output -> EC2 input
module "ec2" {
  vpc_security_group_ids = [module.web_sg.security_group_id]  # <-- output from sg module
}
```

Each `module.<name>.<output>` reference tells Terraform two things:
1. Where to get the value at plan/apply time
2. That a dependency exists (the referenced module must be created first)

### Step 3: Read Module Documentation

Before applying, check each module's registry page to understand what you are deploying:

- [VPC Module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest) -- look at `Inputs` and `Outputs` tabs
- [Security Group Module](https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/latest) -- note the `ingress_with_cidr_blocks` input format
- [EC2 Instance Module](https://registry.terraform.io/modules/terraform-aws-modules/ec2-instance/aws/latest) -- review available outputs

Practice finding answers to these questions:
- What output from the VPC module gives you the NAT gateway's Elastic IP?
- What input on the SG module lets you add egress rules?
- What output from the EC2 module gives you the instance's private IP?

### Step 4: Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Update `terraform.tfvars` with real values:
- Set `instance_ami` to a valid AMI in your region:
  ```bash
  aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=al2023-ami-2023.*-x86_64" \
    --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" \
    --output text
  ```
- Set `allowed_ssh_cidrs` to your IP: `["$(curl -s https://checkip.amazonaws.com)/32"]`
- Set `key_name` to an existing key pair, or remove the line to skip SSH

### Step 5: Initialize and Plan

```bash
terraform init
terraform plan
```

During `terraform plan`, observe:
- How many resources each module creates (VPC creates ~20+ resources)
- The dependency order Terraform determines
- How outputs from one module appear as inputs in another's plan output

### Step 6: Apply and Verify

```bash
terraform apply
```

After apply completes:
```bash
# Get the web server URL from outputs
terraform output web_url

# Verify the web server responds
curl $(terraform output -raw instance_public_ip)
```

### Step 7: Inspect the Dependency Graph

```bash
terraform graph | dot -Tpng > graph.png
```

Open `graph.png` to visualize how Terraform understood the module dependencies. You will see `module.vpc` feeds into both `module.web_sg` and `module.ec2`, and `module.web_sg` feeds into `module.ec2`.

### Step 8: Clean Up

```bash
terraform destroy
```

## Exercises

### Exercise 1: Add a Second Instance

Add another `module "ec2_secondary"` block that places an instance in the second public subnet (`module.vpc.public_subnets[1]`). Attach the same security group. Observe how Terraform handles the parallel creation.

### Exercise 2: Create a Private Instance

Add an instance in a private subnet. It should NOT have a public IP. Consider: what security group rules does it need? Can it reach the internet (hint: NAT gateway)?

### Exercise 3: Split Security Groups

Create a separate security group for SSH access. Attach both the web SG and SSH SG to the EC2 instance using `vpc_security_group_ids = [module.web_sg.security_group_id, module.ssh_sg.security_group_id]`.

### Exercise 4: Use Data Sources Instead of Variables

Replace the `instance_ami` variable with an `aws_ami` data source that automatically finds the latest Amazon Linux 2023 AMI. Pass `data.aws_ami.al2023.id` to the EC2 module.

## How to Read Module Documentation

When evaluating a new terraform-aws-modules module:

1. **Start with the README** -- it shows the simplest working example
2. **Check `examples/`** -- find the example closest to your use case (usually `simple/` or `complete/`)
3. **Read `variables.tf`** -- every input is documented with type, description, and default
4. **Read `outputs.tf`** -- these are the values you can chain to other modules
5. **Check the version** -- use the `~>` constraint to allow patch updates but not breaking changes
6. **Review open issues** -- search for your use case to see if others hit problems

The Terraform Registry provides the same information in a browsable format with the `Inputs`, `Outputs`, `Resources`, and `Dependencies` tabs.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Missing `version` on module source | Always pin: `version = "~> 5.0"` |
| Referencing an output that doesn't exist | Check the module's `outputs.tf` or registry docs |
| Wrong output type (string vs list) | VPC subnets are lists; use `[0]` to get a single ID |
| Forgetting the external network dependency | The SG module needs `vpc_id`; without it, it uses the default VPC |
| Hardcoding values that should be outputs | If a value comes from another module, always reference it |

## Success Criteria

- `terraform plan` succeeds with no errors
- `terraform apply` creates all resources across all three modules
- The web server responds to HTTP requests on port 80
- You can explain which outputs flow between which modules and why
- You can add a fourth module that consumes outputs from the existing three

## Estimated Time

- Reading and understanding the configuration: 15 minutes
- Configuring variables and initializing: 10 minutes
- Planning and applying: 10 minutes
- Exploring the dependency graph: 10 minutes
- Exercises: 20-30 minutes
- **Total: ~65-75 minutes**
