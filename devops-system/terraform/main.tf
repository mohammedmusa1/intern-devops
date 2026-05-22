terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "github" {
  token = var.github_pat
  owner = split("/", replace(replace(var.github_repo, "https://github.com/", ""), ".git", ""))[0]
}

# 1. VPC & Networking
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "devops-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "devops-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name = "devops-public-subnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "devops-route-table"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# 2. Security Group
resource "aws_security_group" "devops_sg" {
  name        = "devops-sg"
  description = "Allow required ports for DevOps stack"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 30090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-sg"
  }
}

# 3. SSH Key Pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "random_id" "id" {
  byte_length = 4
}

resource "aws_key_pair" "generated_key" {
  key_name   = "devops-key-${random_id.id.hex}"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/devops-key.pem"
}

# 4. AMI Data Source (Ubuntu 24.04 LTS)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 5. EC2 Instance
resource "aws_instance" "devops" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.generated_key.key_name
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.devops_sg.id]

  root_block_device {
    volume_type = "gp3"
    volume_size = 29
  }

  user_data = templatefile("${path.module}/../scripts/userdata.sh", {
    jenkins_values     = templatefile("${path.module}/../jenkins/values.yaml", { 
        github_repo = var.github_repo, 
        github_pat = var.github_pat, 
        dockerhub_username = var.dockerhub_username, 
        dockerhub_token = var.dockerhub_token 
    })
    argocd_values      = file("${path.module}/../argocd/values.yaml")
    argocd_application = templatefile("${path.module}/../argocd/application.yaml", { 
        github_repo = var.github_repo 
    })
    prometheus_values  = file("${path.module}/../monitoring/prometheus-values.yaml")
    grafana_values     = file("${path.module}/../monitoring/grafana-values.yaml")
    ingress_values     = file("${path.module}/../helm/ingress-nginx-values.yaml")
  })

  tags = {
    Name = "DevOps-Server"
  }
}

# 6. Elastic IP
resource "aws_eip" "devops_eip" {
  instance = aws_instance.devops.id
  domain   = "vpc"
}

# 7. GitHub Webhook for Jenkins
resource "github_repository_webhook" "jenkins" {
  repository = split("/", replace(replace(var.github_repo, "https://github.com/", ""), ".git", ""))[1]
  
  configuration {
    url          = "http://${aws_eip.devops_eip.public_ip}:30080/github-webhook/"
    content_type = "json"
    insecure_ssl = true
  }

  active = true
  events = ["push"]
}
