terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# --- Variables for Portability ---
locals {
  private_key_path = pathexpand("~/.ssh/id_rsa")
  public_key_path  = pathexpand("~/.ssh/id_rsa.pub")
}

# --- Security Group ---
resource "aws_security_group" "redmine_sg" {
  name        = "redmine-security-group"
  description = "Allow SSH and Redmine traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Key Pair ---
resource "aws_key_pair" "deployer" {
  key_name   = "redmine-key"
  public_key = file(local.public_key_path)
}

# --- EC2 Instance ---
resource "aws_instance" "redmine_vm" {
  ami           = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS (US-East-1)
  instance_type = "t3.micro"
  key_name      = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.redmine_sg.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  # Inject Public Key into cloud-init
  user_data = templatefile("cloud-init.yaml", {
    public_key = file(local.public_key_path)
  })

  # Connection details for all provisioners
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(local.private_key_path)
    host        = self.public_ip
  }

  # Create folders for reliable uploads
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/ubuntu/redmine"
    ]
  }

  # Upload Configuration Files
  provisioner "file" {
    source      = "docker-compose.yml"
    destination = "/home/ubuntu/redmine/docker-compose.yml"
  }

  provisioner "file" {
    source      = ".env"
    destination = "/home/ubuntu/redmine/.env"
  }

  # Upload the Image
  provisioner "file" {
    source      = "redmine-release.tar.gz"
    destination = "/home/ubuntu/redmine/redmine-release.tar.gz"
  }

  # Activate the Application
  provisioner "remote-exec" {
    inline = [
      # Wait for cloud-init to finish
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 5; done",
      
      # Wait for Docker
      "until docker info >/dev/null 2>&1; do echo 'Waiting for Docker service...'; sleep 5; done",
      
      # Load the image
      "docker load < /home/ubuntu/redmine/redmine-release.tar.gz",
      
      # Enter the folder before running compose
      "cd /home/ubuntu/redmine && docker compose up -d"
    ]
  }
}

# Create a Static IP
resource "aws_eip" "redmine_ip" {
  instance = aws_instance.redmine_vm.id
  domain   = "vpc"
}

output "app_url" {
  value = "http://${aws_eip.redmine_ip.public_ip}:3000"
}

# Backup to S3
resource "aws_s3_bucket" "backup_bucket" {
  bucket_prefix = "redmine-backups-"
}

resource "aws_iam_role" "s3_role" {
  name = "redmine_backup_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17", Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy" "s3_access" {
  name = "s3_access"
  role = aws_iam_role.s3_role.id
  policy = jsonencode({
    Version = "2012-10-17", Statement = [{ Action = ["s3:PutObject", "s3:ListBucket"], Effect = "Allow", Resource = [aws_s3_bucket.backup_bucket.arn, "${aws_s3_bucket.backup_bucket.arn}/*"] }]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "redmine_profile"
  role = aws_iam_role.s3_role.name
}

output "backup_bucket_name" {
  value = aws_s3_bucket.backup_bucket.id
}
