terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "vpc_jerusalem" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name      = "VPC PA Jerusalem"
    Owner     = "Douglas"
    CreatedAt = "2024-02-23"
  }

}

#Creat subnet public us-east-1a
resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.vpc_jerusalem.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "public-subnet-1a"
    Type = "Public"
  }
}

#Creat subnet private 
resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.vpc_jerusalem.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-subnet-1a"
    Type = "Private"
  }
}

#Creat subnet public us-east-1b
resource "aws_subnet" "subnet3" {
  vpc_id            = aws_vpc.vpc_jerusalem.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "public-subnet-1b"
    Type = "Public"
  }
}

#Creat subnet private 
resource "aws_subnet" "subnet4" {
  vpc_id            = aws_vpc.vpc_jerusalem.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "private-subnet-1b"
    Type = "Private"
  }
}

## Configuring internet gateway
resource "aws_internet_gateway" "vpc_jerusalem" {
  vpc_id = aws_vpc.vpc_jerusalem.id

  tags = {
    Name      = "pa-jerusalem-vpc-igw"
    Owner     = "Douglas"
    CreatedAt = "2023-02-23"
  }
}

# habilitando ip elastico
resource "aws_eip" "nat" {
  vpc = true
}

#Configurando NAT
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.subnet1.id

  tags = {
    Name = "pa-jerusalem-nat-public"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.vpc_jerusalem]
}

# Configuring route table
resource "aws_route_table" "rt1" {
  vpc_id = aws_vpc.vpc_jerusalem.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_jerusalem.id
  }

  tags = {
    Name = "rtb-public"
  }
}

resource "aws_route_table" "rt2" {
  vpc_id = aws_vpc.vpc_jerusalem.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "rtb-private1-us-east-1a"
  }
}

resource "aws_route_table" "rt3" {
  vpc_id = aws_vpc.vpc_jerusalem.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "rtb-private1-us-east-1b"
  }
}


# Configuring route table association
resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.rt1.id
}

resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.rt2.id
}

resource "aws_route_table_association" "rta3" {
  subnet_id      = aws_subnet.subnet3.id
  route_table_id = aws_route_table.rt1.id
}

resource "aws_route_table_association" "rta4" {
  subnet_id      = aws_subnet.subnet4.id
  route_table_id = aws_route_table.rt3.id
}


# Criando security group // Resource: aws_security_group
resource "aws_security_group" "webserver" {
  name        = "terraform-sg-web"
  description = "Webserver network traffic"
  vpc_id      = aws_vpc.vpc_jerusalem.id

  tags = {
    Name = "Terraform Sg"
  }
}

# Criando Regra de entrada para liberar a porta 22 // Resource: aws_security_group_rule
resource "aws_security_group_rule" "app_server_sg_inbound_22" {
  description = "SSH from anywhere"
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  # ipv6_cidr_blocks  = [aws_vpc.vpc_terraform.ipv6_cidr_block]
  security_group_id = aws_security_group.webserver.id ##Resource: aws_vpc_endpoint_security_group_association
}

# Criando Regra de entrada para liberar a porta 80 // Resource: aws_security_group_rule
resource "aws_security_group_rule" "app_server_sg_inbound_80" {
  description = "80 from anywhere"
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  # ipv6_cidr_blocks  = [aws_vpc.vpc_terraform.ipv6_cidr_block]
  security_group_id = aws_security_group.webserver.id ##Resource: aws_vpc_endpoint_security_group_association
}

# Criando Regra de saída
resource "aws_security_group_rule" "app_server_sg_outbound" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  #ipv6_cidr_blocks  = [aws_vpc.vpc_terraform.ipv6_cidr_block]
  security_group_id = aws_security_group.webserver.id
}