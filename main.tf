# Creating a new VPC
resource "aws_vpc" "my_vpc" {
  cidr_block           = var.vpc_address
  enable_dns_hostnames = true

  tags = {
    Name = "my_vpc"
  }
}

# Creating Public Subnet for 
resource "aws_subnet" "public_subnet" {
  count                   = length(data.aws_availability_zones.az.names)
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = element(var.public_subnets, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet"
  }
}

# Creating Private Subnet for database
resource "aws_subnet" "private_subnet" {
  count      = length(data.aws_availability_zones.az.names)
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = element(var.private_subnets, count.index)

  tags = {
    Name = "private_subnet"
  }
}

# Creating Database Subnet group for RDS under our VPC
resource "aws_db_subnet_group" "db_subnet" {
  name       = "rds_db"
  subnet_ids = [aws_subnet.private_subnet.id]

  tags = {
    Name = "My DB subnet group"
  }
}

# Creating Public Facing Internet Gateway
resource "aws_internet_gateway" "public_internet_gw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "public_facing_internet_gateway"
  }
}

# Route Table connecting to Nat Gateway
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.my_vpc.id
}

# Route 
resource "aws_route" "r" {
  route_table_id              = aws_route_table.rt.id
  destination_ipv4_cidr_block = "0.0.0.0/0"
  nat_gateway_id              = aws_nat_gateway.ngw.id
}

# Nat Gateway
resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.private_subnet.id
}

# 
resource "aws_eip" "nat_eip" {
  count                     = length(data.aws_subnet.private_subnet.id)
  associate_with_private_ip = element(var.private_subnets, count.index)
  vpc                       = true
}


# # Associating Public Subnet 
# resource "aws_route_table_association" "associate_subnet" {
#   subnet_id      = aws_subnet.public_subnet.id
#   route_table_id = aws_default_route_table.gw_router.id
# }


# Creating a new security group for public subnet 
resource "aws_security_group" "SG_public_subnet" {
  name        = "ECS_security_group"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from VPC"
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
}

# Creating a new security group for private subnet 
resource "aws_security_group" "SG_private_subnet_" {
  name        = "Postgres_security_group"
  description = "Postgres"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = "Postgres Port"
    from_port   = 5432
    to_port     = 5432
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



# Launching RDS db instance
resource "aws_db_instance" "DataBase" {
  allocated_storage      = 20
  max_allocated_storage  = 100
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "9.6.9"
  instance_class         = "db.t2.micro"
  name                   = "mydb"
  username               = "vikrant"
  password               = "vikrant1234"
  parameter_group_name   = "default.postgres"
  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids = [aws_security_group.SG_private_subnet_.id]
  skip_final_snapshot    = true

  provisioner "local-exec" {
    command = "echo ${aws_db_instance.DataBase.endpoint} > DB_host.txt"
  }

}
