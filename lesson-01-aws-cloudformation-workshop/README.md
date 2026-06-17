---
title: "AWS CloudFormation Workshop"
type: lab
difficulty: beginner
tier: free
platform: "AWS"
url: "https://catalog.workshops.aws/cfn101/"
tags: ["aws", "cloudformation", "iac", "workshop"]
---

# AWS CloudFormation Workshop

## Overview

The AWS CloudFormation Workshop (CFN101) is AWS's official hands-on workshop for learning Infrastructure as Code with CloudFormation from the ground up. Hosted on AWS Workshop Studio, it provides a structured, progressive curriculum that takes you from writing your first template to building complex, production-grade stacks with nested resources, custom logic, and reusable patterns.

What sets CFN101 apart from static documentation is its learn-by-doing approach. Each module introduces a CloudFormation concept, explains the underlying mechanics, and then walks you through a hands-on lab where you deploy real AWS resources. You start with a simple EC2 instance and progressively layer on parameters, mappings, conditions, outputs, and nested stacks until you have a working understanding of how CloudFormation templates are structured and deployed.

The workshop is beginner-friendly but covers enough depth to bridge into intermediate territory. By the end, you will understand not just the syntax of CloudFormation templates but the reasoning behind design decisions like parameterization, resource dependencies, and stack composition. This makes it an ideal starting point before moving on to higher-level tools like AWS CDK.

## Prerequisites

- An active AWS account (a personal or sandbox account is recommended to avoid impacting production workloads)
- Basic familiarity with the AWS Management Console and navigating between services
- A text editor or IDE for writing YAML or JSON templates (VS Code with the CloudFormation Linter extension is recommended)
- Foundational understanding of at least one AWS compute service (EC2, Lambda) and networking concepts (VPC, subnets, security groups)
- Willingness to deploy real AWS resources that may incur small costs (most labs stay within free-tier limits, but some do not)

## Key Takeaways

1. **Understand template anatomy** - Learn the structure of a CloudFormation template including AWSTemplateFormatVersion, Description, Parameters, Mappings, Conditions, Resources, and Outputs sections, and when to use each one.
2. **Deploy and update stacks confidently** - Practice the full lifecycle of creating, updating, and deleting CloudFormation stacks through both the console and CLI, understanding change sets and rollback behavior.
3. **Parameterize templates for reuse** - Build templates that accept runtime parameters, use mappings for environment-specific values, and apply conditions to toggle resources on or off based on deployment context.
4. **Compose stacks with nesting and cross-stack references** - Break monolithic templates into modular, nested stacks and use exports and imports to share values between independent stacks.
5. **Validate and lint templates before deployment** - Integrate cfn-lint and the CloudFormation ValidateTemplate API into your workflow to catch errors before they reach the deployment phase.

## How to Use

### Step 1: Access the Workshop

Navigate to the CloudFormation Workshop at [catalog.workshops.aws/cfn101](https://catalog.workshops.aws/cfn101). Review the workshop introduction and module outline to understand the progression of topics. No registration is required to view the content, but you will need an AWS account to complete the labs.

### Step 2: Set Up Your Environment

Prepare your local and AWS environment before starting the labs:

1. Sign into the AWS Management Console with an IAM user that has administrator access (or use an AWS-provided event account if attending a guided session)
2. Select a single AWS Region and use it consistently throughout all labs
3. Install the AWS CLI and configure it with your credentials using `aws configure`
4. Install cfn-lint (`pip install cfn-lint`) to validate templates locally before deploying
5. Open your preferred text editor and create a working directory for your template files

### Step 3: Work Through the Foundational Modules

Start with the introductory modules that cover core CloudFormation concepts:

1. Complete the Template Anatomy module to understand how each section of a template functions
2. Deploy your first stack with a basic EC2 instance resource to establish the create-update-delete workflow
3. Add Parameters to your template to make instance type and key pair configurable at deploy time
4. Implement Mappings to look up AMI IDs per region, removing hard-coded values
5. Use Outputs to expose resource identifiers like instance IDs and public IP addresses from your stack

### Step 4: Progress to Intermediate Topics

Once the fundamentals are solid, work through the more advanced modules:

1. Apply Conditions to conditionally create resources based on parameter values (e.g., only create an Elastic IP in production)
2. Build Nested Stacks to compose a VPC stack, a security group stack, and an application stack into a parent template
3. Explore Custom Resources to extend CloudFormation with Lambda-backed logic for operations CloudFormation does not natively support
4. Practice stack updates with Change Sets to preview modifications before applying them to running infrastructure

### Step 5: Clean Up Resources

After completing the labs, remove all deployed resources to avoid ongoing charges:

1. Navigate to the CloudFormation console and identify all stacks created during the workshop
2. Delete stacks in reverse dependency order (child/nested stacks before parent stacks)
3. Verify that all associated resources (EC2 instances, VPCs, security groups) have been terminated
4. Check for any retained resources such as S3 buckets with deletion policies that prevent automatic removal
5. Review your AWS Cost Explorer the following day to confirm no unexpected charges remain

## Practice Notes

- Run hands-on work in a sandbox and keep a short lab log with commands, screenshots or outputs, resources created, cleanup steps, and the one pattern you would reuse in production.
- Translate the lesson into an IaC operating habit: repeatable plans, state safety, reviewable diffs, module boundaries, policy checks, and cleanup of any billable resources.
- Completion checkpoint: you can explain the core idea without notes and reproduce the smallest useful example from the resource.
- Portfolio artifact: create a short note titled "AWS CloudFormation Workshop - applied takeaway" with the scenario you used, the decision you made, and one follow-up task you would assign to yourself or a team.

## Related Resources

- [AWS CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/) - Official reference for all resource types, intrinsic functions, and template syntax
- [cfn-lint](https://github.com/aws-cloudformation/cfn-lint) - Open-source CloudFormation linter that validates templates against the resource specification and best practices
- [AWS CDK Workshop](https://cdkworkshop.com/) - The natural next step after CFN101, using familiar programming languages to generate CloudFormation templates
- [AWS CloudFormation Designer](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/working-with-templates-cfn-designer.html) - Visual tool for creating and modifying CloudFormation templates with a drag-and-drop interface
- [Former2](https://github.com/iann0036/former2) - Generate CloudFormation templates from existing AWS resources for reverse-engineering infrastructure into code

## Estimated Time

- **Workshop orientation and environment setup**: 30-45 minutes
- **Foundational modules (template anatomy, resources, parameters, mappings, outputs)**: 2-3 hours
- **Intermediate modules (conditions, nested stacks, custom resources, change sets)**: 2-3 hours
- **Resource cleanup and cost verification**: 15-30 minutes
- **Total for the full workshop**: ~4-6 hours across one or more sessions
