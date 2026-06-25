# Lab: Fix the Broken CloudFormation Template

## Objective

You have been given a CloudFormation template (`broken-template.yaml`) that is supposed to deploy a basic web server stack consisting of:

- A VPC with a public subnet
- An Internet Gateway with a route table
- A Security Group allowing HTTP (80), HTTPS (443), and SSH (22) traffic
- An EC2 instance running a simple web server

However, the template contains **4 bugs** that prevent it from being deployed. Your job is to find and fix each one.

## Prerequisites

- AWS CLI configured with valid credentials
- Basic understanding of CloudFormation YAML syntax
- Familiarity with AWS networking concepts (VPC, Subnet, Security Group)

## Instructions

1. Open `broken-template.yaml` in your editor
2. Attempt to validate the template using the AWS CLI:

   ```bash
   aws cloudformation validate-template --template-body file://broken-template.yaml
   ```

3. Read through the template carefully, looking for structural and logical errors
4. Fix each bug you find
5. Re-validate until the template passes validation
6. (Optional) Deploy the stack to confirm it works:

   ```bash
   aws cloudformation create-stack \
     --stack-name lab-webserver \
     --template-body file://broken-template.yaml \
     --region us-east-1
   ```

## The Bugs

There are exactly **4 bugs** in the template:

| # | Category | Hint |
|---|----------|------|
| 1 | Missing resource property | Every resource in a CloudFormation template must have a `Type` property. One resource is missing it entirely. |
| 2 | Missing required property | EC2 instances need to know which AMI to boot from. Check the `AWS::EC2::Instance` resource. |
| 3 | Invalid property value | CIDR blocks must include a prefix length (e.g., `10.0.0.0/16`). Look at the network configuration. |
| 4 | Circular dependency | A `DependsOn` creates an impossible deployment order. Two resources cannot both depend on each other. |

## Validation Tips

- `aws cloudformation validate-template` catches syntax errors but NOT all logical errors
- Some bugs (like circular dependencies) only surface during stack creation
- Read the error messages carefully; they often point directly to the problem
- Use the [CloudFormation Resource Reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html) to check required properties

## Success Criteria

Your fixed template should:

- Pass `aws cloudformation validate-template` without errors
- Successfully create a stack when deployed
- Result in a running EC2 instance accessible on port 80

## Solution

Once you have attempted the fixes, compare your work against `solution/fixed-template.yaml`.
