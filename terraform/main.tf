#####################################
# Provider
#####################################

provider "aws" {
  region = var.aws_region
}

###########################################
# Data Source - Gets AWS Availability Zones
###########################################

data "aws_availability_zones" "available" {
  state = "available"
}

###########################################
# Resource - VPC and Subnets
###########################################

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "${var.name_prefix}-vpc"
  }

}

############# Public Subnets #############

resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, 0)
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.name_prefix}-public-1"
  }
}
resource "aws_subnet" "public2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, 1)
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "${var.name_prefix}-public-2"
  }
}
resource "aws_subnet" "public3" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, 2)
  availability_zone = data.aws_availability_zones.available.names[2]
  tags = {
    Name = "${var.name_prefix}-public-3"
  }
}

############# Private Subnets #############

resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, 7)
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "${var.name_prefix}-private-1"
  }
}
resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, 8)
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "${var.name_prefix}-private-2"
  }
}
resource "aws_subnet" "private3" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, 9)
  availability_zone = data.aws_availability_zones.available.names[2]
  tags = {
    Name = "${var.name_prefix}-private-3"
  }
}

###########################################
# IGW and Public Route Table
###########################################

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.name_prefix}-igw"
  }
}

############ Public Route Table ############

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "${var.name_prefix}-public-rt"
  }
}

########## Route Table Associations ##########

resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public3" {
  subnet_id      = aws_subnet.public3.id
  route_table_id = aws_route_table.public.id
}

###########################################
# NAT Gateway and Private Route Table
###########################################

########## NAT Gateway ##########

resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "${var.name_prefix}-nat-eip"
  }
}
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public1.id
  tags = {
    Name = "${var.name_prefix}-nat-gw"
  }
}

########## Private Route Table ##########

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "${var.name_prefix}-private-rt"
  }

}

########## Route Table Associations ##########

resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "private3" {
  subnet_id      = aws_subnet.private3.id
  route_table_id = aws_route_table.private.id
}

###########################################
# Launch Template
###########################################

resource "aws_launch_template" "asg_lt" {
  name          = "${var.name_prefix}_asg_lt"
  image_id      = var.ami_main
  instance_type = var.instance_type
  key_name      = var.key_name
  vpc_security_group_ids = [
    aws_security_group.asg_elb_access_sg.id,
    aws_security_group.asg_ssh_access_sg.id
  ]
  iam_instance_profile {
    arn = aws_iam_instance_profile.asg_bucket_profile.arn
  }

}

###########################################
# Autoscaling Group
###########################################

resource "aws_autoscaling_group" "asg" {
  name = "${var.name_prefix}_asg"
  launch_template {
    id      = aws_launch_template.asg_lt.id
    version = "$Latest"
  }
  max_size          = 5
  min_size          = 1
  health_check_type = "ELB"
  desired_capacity  = 2
  vpc_zone_identifier = [
    aws_subnet.private1.id,
    aws_subnet.private2.id,
    aws_subnet.private3.id
  ]
  target_group_arns = [
    aws_lb_target_group.lb_tg.arn
  ]
}

###########################################
# Load Balancer
###########################################

resource "aws_lb" "elb" {
  name            = "${var.name_prefix}-elb"
  security_groups = [aws_security_group.elb_sg.id]
  subnets = [
    aws_subnet.public1.id,
    aws_subnet.public2.id,
    aws_subnet.public3.id
  ]
}
resource "aws_lb_target_group" "lb_tg" {
  name     = "${var.name_prefix}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/"
    port                = "traffic-port"
  }
}
resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.elb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_tg.arn
  }
}

###########################################
# Bastion Host
###########################################

resource "aws_instance" "bastion" {
  ami           = var.ami_bastion
  instance_type = var.instance_type
  key_name      = var.key_name
  vpc_security_group_ids = [
    aws_security_group.bastion_sg.id
  ]
  subnet_id = aws_subnet.public1.id
  tags = {
    Name = "${var.name_prefix}-bastion"
  }
}
##################################################
# Security Groups
##################################################

############# ASG Security Groups ############

######### Access From Load Balancer ############

resource "aws_security_group" "asg_elb_access_sg" {
  name        = "${var.name_prefix}_asg_elb_access_sg"
  description = "Allow HTTP access from load balancer"
  vpc_id      = aws_vpc.main.id
  ingress {
    description     = "Allow HTTP from Load Balancer"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.elb_sg.id]
  }
  ingress {
    description     = "Allow HTTPS from Load Balancer"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.elb_sg.id]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

############## SSH from Bastion Host ##############

resource "aws_security_group" "asg_ssh_access_sg" {
  name        = "${var.name_prefix}_asg_ssh_access_sg"
  description = "Allow SSH access from Bastion Host"
  vpc_id      = aws_vpc.main.id
  ingress {
    description     = "Allow SSH from Bastion Host"
    from_port       = "22"
    to_port         = "22"
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

############## Bastion Host Security Group ##############

resource "aws_security_group" "bastion_sg" {
  name        = "${var.name_prefix}_bastion_sg"
  description = "Allow SSH access from My IP"
  vpc_id      = aws_vpc.main.id
  ingress {
    description = "Allow SSH from my IP"
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

########## Load Balancer Security Group ##########

resource "aws_security_group" "elb_sg" {
  name        = "${var.name_prefix}_elb_sg"
  description = "Allow HTTP access from anywhere"
  vpc_id      = aws_vpc.main.id
  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

#############################################
# Instance Profile - Allows Instances 
# Read/Write Access to S3 Bucket
#############################################

resource "aws_iam_role_policy" "policy" {
  name = "${var.name_prefix}_read_only_policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "PerformBucketActions",
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket",
          "s3:GetObject",
        ],
        "Resource" : [
          var.bucket_arn,
          "${var.bucket_arn}/*"
        ]
      }
    ]
  })
  role = aws_iam_role.asg_bucket_role.name
}

resource "aws_iam_role" "asg_bucket_role" {
  name = "${var.name_prefix}_asg_bucket_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_instance_profile" "asg_bucket_profile" {
  name = "${var.name_prefix}_instance_profile"
  role = aws_iam_role.asg_bucket_role.name
}
