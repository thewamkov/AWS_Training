# set provider
provider "aws" {
  region = "us-east-2"
}


# Create vpc
resource "aws_vpc" "vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "main"
  }
}


# disble acces from
resource "aws_network_acl" "acl" {
  vpc_id = aws_vpc.vpc.id

  egress {
    protocol   = -1
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}


# Create subnets
resource "aws_subnet" "SB" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-2a"

  
}


resource "aws_subnet" "SB2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2b"
  map_public_ip_on_launch = true

}


resource "aws_db_subnet_group" "DbSG" {
  name       = "main"
  subnet_ids = [aws_subnet.SB.id, aws_subnet.SB2.id]
  

  tags = {
    Name = "My DB subnet group"
  }
}


# Create internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "main"
  }
}



# Create custom route table
resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "main"
  }
}


# associate route table with subnet
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.SB.id
  route_table_id = aws_route_table.RT.id
}


# Create security group for RDS
resource "aws_security_group" "SG"{

    name = "ELB_SG"
    vpc_id = aws_vpc.vpc.id

    ingress {
        from_port   = 3306
        to_port     = 3306
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
       Name = "ELB_SG"
   }
}


# Create RDS instance
resource "aws_db_instance" "RDS" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = var.dbname
  username             = var.username
  password             = var.password
  publicly_accessible = true
  skip_final_snapshot = true
  parameter_group_name = "default.mysql5.7"
  vpc_security_group_ids = [ aws_security_group.SG.id  ]
  db_subnet_group_name = aws_db_subnet_group.DbSG.id
}