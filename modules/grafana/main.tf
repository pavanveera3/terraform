#ssh-keygen -t rsa -b 4096 -C "your_email@example.com" -f my-key-pair
terraform {
  required_providers{
    grafana = {
      source = "grafana/grafana"
      }
    }
}

variable "vpc_id" {
  description = "ID of the existing VPC."
}

variable "subnet_id" {
  description = "ID of the existing subnet."
}
variable "region" {
  description = "AWS region where the resources will be created."
}

provider "aws" {
  region = var.region  # Replace with your desired region
}

resource "aws_security_group" "grafana_sg" {
  name        = "grafana-sg"
  description = "Security group for Grafana"
  vpc_id = var.vpc_id  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 3000  # Grafana port
    to_port     = 3000  # Grafana port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 80   # HTTP port
    to_port     = 80   # HTTP port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443   # HTTPS port
    to_port     = 443   # HTTPS port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Add more rules as needed for other ports
}


# Create an IAM policy for CloudWatch Full Access
resource "aws_iam_policy" "cloudwatch_full_access_policy" {
  name        = "CloudWatchFullAccessPolicy_1"
  description = "Policy for full access to CloudWatch Logs and Metrics"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = [
          "cloudwatch:Get*",
          "cloudwatch:List*",
          "logs:GetLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

# Create an IAM role and attach the CloudWatch Full Access policy
resource "aws_iam_role" "ec2_role" {
  name = "EC2Role_1"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "demo-attach" {
  name       = "demo-attachment"
  roles      = [aws_iam_role.ec2_role.name]
  policy_arn = aws_iam_policy.cloudwatch_full_access_policy.arn
}

resource "aws_iam_instance_profile" "demo-profile" {
  name = "demo_profile_1"
  role = aws_iam_role.ec2_role.name
}

resource "aws_key_pair" "my_key_pair" {
  key_name   = "my-key-pair_1"  # Replace with your desired key name
  public_key = file("${path.module}/my-key-pair.pub")
}


resource "aws_instance" "grafana_instance" {
  ami           = "ami-0baa3f62c0ca83387"  # Replace with the actual AMI ID
  instance_type = "t2.micro"  # Replace with the desired instance type
  key_name      = aws_key_pair.my_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.grafana_sg.id]
  iam_instance_profile = aws_iam_instance_profile.demo-profile.name
  subnet_id = var.subnet_id
  associate_public_ip_address = true 
  tags = {
    Name = "grafana-instance"
  }

  provisioner "remote-exec" {
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("${path.module}/my-key-pair")
    host        = self.public_ip
  }

    inline = [
      "sudo yum update -y",
      "sudo yum install -y https://dl.grafana.com/oss/release/grafana-8.5.0-1.x86_64.rpm",
      "sudo systemctl start grafana-server",
      "sudo systemctl enable grafana-server"
    ]
  }
}

provider "grafana" {
url = "http://${aws_instance.grafana_instance.public_ip}:3000"
auth = "admin:admin"
}


resource "aws_vpc_endpoint" "cloudwatch" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.ca-central-1.logs"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.grafana_sg.id]
  subnet_ids          = [var.subnet_id]
}


# Create a security group association for the VPC endpoint
resource "aws_vpc_endpoint_security_group_association" "cloudwatch_sg_association" {
  security_group_id    = aws_security_group.grafana_sg.id
  vpc_endpoint_id      = aws_vpc_endpoint.cloudwatch.id
}


resource "grafana_data_source" "cloudwatch" {
  name       = "CloudWatch"
  type       = "cloudwatch"
  url = "https://${aws_vpc_endpoint.cloudwatch.dns_entry[0]["dns_name"]}"

  #url        = "https://vpce-079a1aee424a7bb20-w0dzckum-ca-central-1d.logs.ca-central-1.vpce.amazonaws.com"  # Replace with the CloudWatch endpoint of your region
}

output "url" {
  value = aws_vpc_endpoint.cloudwatch.dns_entry[0]["dns_name"]
}

output "instance_public_ip" {
  value = aws_instance.grafana_instance.public_ip
}

