provider "aws" {
    region = "us-east-1"
    access_key = AWS_ACCESS_KEY_ID
    secret_key = AWS_SECRET_ACCESS_KEY
}

# Creating an EC2 instance
resource "aws_instance" "first-ec2" {
    ami = "ami-0e2c8caa4b6378d8"
    instance_type = "t2.micro"

    tags = {
        Name = "Portfolio-Server"
    }
}

# Creating a VPC
resource "aws_vpc" "my-vpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
      Name = "Prod-VPC"
    }
}

# Creating a subnet within the VPC
resource "aws_subnet" "subnet-1" {
    vpc_id = aws_vpc.my-vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"

    tags = {
      Name = "Prod-Subnet"
    }
}

# Creating an Internet Gateway for the VPC
resource "aws_internet_gateway" "gw-for-my-vpc" {
    vpc_id = aws_vpc.my-vpc.id
}

# Creating Route Table rules for all Traffic
resource "aws_route_table" "route-table" {
    vpc_id =  aws_vpc.my-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gw-for-my-vpc.id
    }  

    route {
        ipv6_cidr_block = "::/0"
        gateway_id = aws_internet_gateway.gw-for-my-vpc.id 
    }

    tags = {
      Name = "Prod"
    }
}

# Associating subnet with Route table 
resource "aws_route_table_association" "a" {
    subnet_id = aws_subnet.subnet-1.id
    route_table_id = aws_route_table.route-table.id
}

# Creating a Security Group to allow on port 22, 80, 443
resource "aws_security_group" "allow-traffic" {
    name        = "allow_web_traffic"
    description = "Allow Web inbound traffic"
    vpc_id      = aws_vpc.my-vpc.id

    ingress {
        description = "HTTPS"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        description = "HTTP"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        description = "SSH"
        from_port   = 22
        to_port     = 22
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
        Name = "allow_web"
    }
}

# Creating a Network Interface with an IP in the subnet
resource "aws_network_interface" "web-server-nic" {
    subnet_id       = aws_subnet.subnet-1.id
    private_ips     = ["10.0.1.50"] 
    security_groups = [aws_security_group.allow-traffic.id]  
}

# Assign an Elastic IP to the Network Interface
resource "aws_eip" "one" {
    domain = "vpc"
    network_interface = aws_network_interface.web-server-nic.id
    associate_with_private_ip = "10.0.1.50"
    depends_on = [ aws_internet_gateway.gw-for-my-vpc ] # dependent on internet gateway to be created first
}

# Create an ubuntu server
resource "aws_instance" "web-server-instance" {
    ami = "ami-0e2c8caa4b6378d8"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"

    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.web-server-nic.id
    }

    user_data = <<-EOF
                #! /bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo your very first web server > /var/www/html/index.html'
                EOF 
    tags = {
        Name = "web-server"
    }
  
}

# To show output for some attribute of a Service
output "public_ip_of_EC2_instacne" {
    value = aws_instance.first-ec2.public_ip  
}