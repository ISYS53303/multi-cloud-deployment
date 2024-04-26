# Create VPC
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/27"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# Create Subnet for VPC
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.0.0/28"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "tf_internet_gateway" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tf_internet_gateway.id
  }
}

resource "aws_route_table_association" "subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Create a Security Group to allow SSH access
resource "aws_security_group" "ssh_access" {
  vpc_id = aws_vpc.vpc.id
}

# Apply ingress/egress rules to Security Group
resource "aws_vpc_security_group_ingress_rule" "ssh_ingress_rule" {
  security_group_id = aws_security_group.ssh_access.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.ssh_access.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_key_pair" "vm_key_pair" {
  key_name   = "terraform-key-pair"
  public_key = file("../credentials/id_rsa.pub")
}

# Create EC2 Instance (AWS Virtual Machine)
resource "aws_instance" "terraform_instance" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.ssh_access.id]
  key_name                    = aws_key_pair.vm_key_pair.key_name
  associate_public_ip_address = true
}

# Outputs
# output "public_ip" {
#   value = aws_instance.terraform_instance.public_ip
# }

output "ssh_command" {
  value = format("ssh -i ../credentials/id_rsa ec2-user@%s", aws_instance.terraform_instance.public_ip)
}
