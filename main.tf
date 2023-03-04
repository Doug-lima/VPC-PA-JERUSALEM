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

# Resource: aws_ec2_instance_state
data "aws_ami" "amazon-linux-2" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }


  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

# Create a VPC
resource "aws_vpc" "vpc_jerusalem" {
  cidr_block = "10.0.0.0/16"
  # enable_dns_hostnames = true
  tags = {
    Name      = "VPC PA Jerusalem"
    Owner     = "Douglas"
    CreatedAt = "2024-02-23"
  }

}

#Creat subnet public us-east-1a
resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.vpc_jerusalem.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
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
  #map_public_ip_on_launch = true
  tags = {
    Name = "private-subnet-1a"
    Type = "Private"
  }
}

#Creat subnet public us-east-1b
resource "aws_subnet" "subnet3" {
  vpc_id                  = aws_vpc.vpc_jerusalem.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
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
  #map_public_ip_on_launch = true
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


# Criando Regra de entrada para liberar a porta 80 // Resource: aws_security_group_rule
resource "aws_security_group_rule" "app_server_sg_inbound_443" {
  description = "443 from anywhere"
  type        = "ingress"
  from_port   = 443
  to_port     = 443
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

#Configurando target Group
resource "aws_lb_target_group" "webserver" {
  name     = "webserver-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc_jerusalem.id

}

#Configurando load balancing / ELB (Elastic Load Balancing)
resource "aws_lb" "alb1" {
  name               = "webserver-application-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet3.id] #Network Mapping

  enable_deletion_protection = false

  /*
  access_logs {
    bucket  = aws_s3_bucket.lb_logs.bucket
    prefix  = "test-lb"
    enabled = true
  }
  */

  tags = {
    Environment = "Prod"
  }
}

#Criando grupo de segurança do elb
resource "aws_security_group" "alb" {
  name        = "alb"
  description = "alb network traffic"
  vpc_id      = aws_vpc.vpc_jerusalem.id

  ingress {
    description = "80 from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.webserver.id]
  }

  tags = {
    Name = "allow traffic"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.alb1.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webserver.arn
  }
}

resource "aws_lb_listener_rule" "rule1" {
  listener_arn = aws_lb_listener.front_end.arn
  priority     = 99

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webserver.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

#Configurando lauch_template / EC2 aws_launch_template
resource "aws_launch_template" "launchtemplate1" {
  name          = "web"
  image_id      = data.aws_ami.amazon-linux-2.id
  instance_type = "t2.micro"
  #key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.webserver.id]
  #associate_public_ip_address = true

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "VM CMS 1"
    }
  }
  user_data = filebase64("${path.module}/ec2.userdata")
}

#Criação do ASG
resource "aws_autoscaling_group" "asg" {
  name                = "webserver-scaling-policy"
  vpc_zone_identifier = [aws_subnet.subnet1.id, aws_subnet.subnet3.id] #Testes feitos na SUBNET PUBLICAS
  health_check_type   = "ELB"
  desired_capacity    = 2
  max_size            = 6
  min_size            = 2

  target_group_arns = [aws_lb_target_group.webserver.arn]

  launch_template {
    id      = aws_launch_template.launchtemplate1.id
    version = "$Latest"
  }
}

#Configuração da Politica de Escalabilidade automática
resource "aws_autoscaling_policy" "web_cluster_target_tracking_policy" {
  name                      = "target-tracking-policy"
  policy_type               = "TargetTrackingScaling"
  autoscaling_group_name    = aws_autoscaling_group.asg.name
  estimated_instance_warmup = 200

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = "60"

  }
}
