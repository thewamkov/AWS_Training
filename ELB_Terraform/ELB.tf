provider "aws" {
    region = "us-east-2"
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
}


# get image id
data "aws_ami" "amazon_test" {
  most_recent = true
  owners = ["self"]
}


# Create security group for ELB
resource "aws_security_group" "SG"{

    name = "ELB_SG"

    ingress {
        from_port   = 80
        to_port     = 80
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


# Create load balancer
resource "aws_lb" "ELB" {
    name = "ELB"
    load_balancer_type = "application"
    subnets = ["subnet-eedc0e85", "subnet-7c363e06"]
    security_groups = [aws_security_group.SG.id]
    
  
}


# Create ec2 from ami
resource "aws_instance" "ec2" {
    ami = data.aws_ami.amazon_test.id
    count = 2
    key_name = "MyKeyPair"
    security_groups = [aws_security_group.SG.name] 
    instance_type = "t2.micro"
    
 
    tags = {
    Name = format("Instance-%d", count.index)
  }
}


# Create Target group, do not need to specify target_type = "instance" because instance by default
resource "aws_lb_target_group" "TG" {
  name = "TG"
  port = 80
  protocol = "HTTP"
  vpc_id = "vpc-f4e04a9f"
}


# Attach instances to TG
resource "aws_lb_target_group_attachment" "TGA_I" {
    count = length(aws_instance.ec2)
    target_group_arn = aws_lb_target_group.TG.arn
    target_id = aws_instance.ec2[count.index].id
    port = 80
    
}


# And finaly create ELB listener
resource "aws_lb_listener" "listener" {
    load_balancer_arn = aws_lb.ELB.arn
    port = 80
    protocol = "HTTP"

    # Set default action
    default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.TG.arn
  }
  
}