#!/bin/bash
set -euo pipefail

yum update -y
yum install -y httpd amazon-cloudwatch-agent

systemctl start httpd
systemctl enable httpd

echo "<h1>${server_name}</h1>" > /var/www/html/index.html

# Start CloudWatch agent for log shipping
systemctl start amazon-cloudwatch-agent
systemctl enable amazon-cloudwatch-agent
