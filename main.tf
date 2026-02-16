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

  # 0. CRITICAL: Create the folder first! 
  # If we don't do this, the file upload will fail because the folder doesn't exist yet.
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/ubuntu/redmine"
    ]
  }

  # 1. Upload Configuration Files (To the new folder)
  provisioner "file" {
    source      = "docker-compose.yml"
    destination = "/home/ubuntu/redmine/docker-compose.yml"
  }

  provisioner "file" {
    source      = ".env"
    destination = "/home/ubuntu/redmine/.env"
  }

  # 2. Upload the Heavy Image (To the new folder)
  provisioner "file" {
    source      = "redmine-release.tar.gz"
    destination = "/home/ubuntu/redmine/redmine-release.tar.gz"
  }

  # 3. Activate the Application
  provisioner "remote-exec" {
    inline = [
      # Wait for cloud-init (Swap creation & Docker install) to finish
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 5; done",
      
      # WAIT for Docker to actually exist and be responsive
      "until docker info >/dev/null 2>&1; do echo 'Waiting for Docker service...'; sleep 5; done",
      
      # Load the image (Updated path)
      "docker load < /home/ubuntu/redmine/redmine-release.tar.gz",
      
      # CRITICAL: Enter the folder before running compose!
      "cd /home/ubuntu/redmine && docker compose up -d"
    ]
  }
}

# 5. Create a Static IP (Elastic IP)
resource "aws_eip" "redmine_ip" {
  instance = aws_instance.redmine_vm.id
  domain   = "vpc"
}

# Update the output to show the static IP
output "app_url" {
  value = "http://${aws_eip.redmine_ip.public_ip}:3000"
}
