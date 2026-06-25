locals {
  instances = { for i in range(var.instance_count) : "web-${i + 1}" => {
    subnet_id = var.subnet_ids[i % length(var.subnet_ids)]
  } }
}

resource "aws_instance" "web" {
  for_each = local.instances

  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = each.value.subnet_id
  vpc_security_group_ids = var.security_group_ids
  iam_instance_profile   = var.instance_profile

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
    server_name = each.key
  }))

  tags = {
    Name = "${var.project_name}-${var.environment}-${each.key}"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/${var.project_name}/${var.environment}/application"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.project_name}-${var.environment}-app-logs"
  }
}
