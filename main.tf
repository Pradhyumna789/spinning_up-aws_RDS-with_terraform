# -------------------
# VPC
# -------------------
resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "my-vpc" }
}

# -------------------
# Public Subnet
# -------------------
resource "aws_subnet" "public-subnet" {
  vpc_id            = aws_vpc.my-vpc.id
  availability_zone = "us-east-1a"
  cidr_block        = "10.0.1.0/24"
  tags = { Name = "us-east-1a-public-subnet-ec2" }
}

# -------------------
# Private Subnet
# -------------------
resource "aws_subnet" "private-subnet" {
  vpc_id            = aws_vpc.my-vpc.id
  availability_zone = "us-east-1b"
  cidr_block        = "10.0.2.0/24"
  tags = { Name = "us-east-1b-private-subnet-rds-db" }
}

resource "aws_subnet" "private-subnet-2" {
  vpc_id            = aws_vpc.my-vpc.id
  availability_zone = "us-east-1c"
  cidr_block        = "10.0.3.0/24"
  tags = { Name = "us-east-1c-private-subnet-rds-db" }
}

# -------------------
# Internet Gateway
# -------------------
resource "aws_internet_gateway" "my-igw" {
  vpc_id = aws_vpc.my-vpc.id
  tags   = { Name = "my-igw" }
}

# -------------------
# Route Table
# -------------------
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.my-vpc.id
  tags   = { Name = "public-rt" }
}

resource "aws_route" "route-to-my-igw" {
  route_table_id         = aws_route_table.public-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my-igw.id
}

resource "aws_route_table_association" "public-subnet-assoc" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public-rt.id
}

# -------------------
# Security Groups
# -------------------
resource "aws_security_group" "ec2-sg" {
  name   = "ec2-sg"
  vpc_id = aws_vpc.my-vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ec2-sg" }
}

resource "aws_security_group" "rds-sg" {
  name   = "rds-sg"
  vpc_id = aws_vpc.my-vpc.id

  ingress {
    description      = "Allow MySQL from EC2"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups  = [aws_security_group.ec2-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "rds-sg" }
}

# -------------------
# EC2 Instance
# -------------------
resource "aws_instance" "my-ec2" {
  ami                         = "ami-0360c520857e3138f"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public-subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ec2-sg.id]
  tags                        = { Name = "my-ec2" }
}

# -------------------
# RDS Subnet Group
# -------------------
resource "aws_db_subnet_group" "my-subnet-group" {
  name       = "rds-ec2-db-subnet-group-1"
  subnet_ids = [aws_subnet.private-subnet.id, aws_subnet.private-subnet-2.id]
  tags       = { Name = "rds-subnet-group" }
}

# -------------------
# RDS Instance
# -------------------
resource "aws_db_instance" "my-db-instance" {
  identifier             = "my-rds-instance"
  engine                 = "mysql"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  username               = "Pradyumna200319"
  password               = "Omvwsuv200319"
  db_subnet_group_name   = aws_db_subnet_group.my-subnet-group.name
  vpc_security_group_ids = [aws_security_group.rds-sg.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
  tags                   = { Name = "my-rds-instance" }
}


# the following is to create an rds cluster with an rds cluster instance
# # create a vpc
# resource "aws_vpc" "my-vpc" {
#   cidr_block = "10.0.0.0/16"
#   tags = {
#     Name = "my-vpc"
#   }
# }

# # deploying a subnet on the vpc
# resource "aws_subnet" "public-subnet" {
#   vpc_id            = aws_vpc.my-vpc.id
#   availability_zone = "us-east-1a"
#   cidr_block        = "10.0.1.0/24"

#   tags = {
#     Name = "us-east-1a-public-subnet-ec2"
#   }
# }

# # create another subnet and keep it private
# resource "aws_subnet" "private-subnet" {
#   vpc_id            = aws_vpc.my-vpc.id
#   availability_zone = "us-east-1b"
#   cidr_block        = "10.0.2.0/24"

#   tags = {
#     Name = "us-east-1a-private-subnet-rds-db"
#   }
# }

# # creating an internet gateway and attaching it to vpc
# resource "aws_internet_gateway" "my-igw" {
#   vpc_id = aws_vpc.my-vpc.id

#   tags = {
#     Name = "public-rt"
#   }
# }

# # create a route table on the vpc
# resource "aws_route_table" "public-rt" {
#   vpc_id = aws_vpc.my-vpc.id

#   tags = {
#     Name = "public-rt"
#   }
# }

# # adding a rule to connect to the internet through the internet gateway attached to the vpc
# resource "aws_route" "route-to-my-igw" {
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = aws_internet_gateway.my-igw.id
#   route_table_id         = aws_route_table.public-rt.id
# }

# # associating the route table to the public-subnet to make it actually public by making the subnet's traffic follow the rules presend in the route-table public-rt
# resource "aws_route_table_association" "associating-public-rt-to-public-subnet" {
#   route_table_id = aws_route_table.public-rt.id
#   subnet_id      = aws_subnet.public-subnet.id
# }

# # creating a security group for the ec2 instance
# resource "aws_security_group" "ec2-sg" {
#   name   = "ec2-sg"
#   vpc_id = aws_vpc.my-vpc.id

#   ingress {
#       description = "allow ssh access from anywhere"
#       from_port   = 22
#       to_port     = 22
#       protocol    = "tcp"
#       cidr_blocks = ["0.0.0.0/0"]
#     }

#     ingress {
#       description = "allow http access from anywhere"
#       from_port   = 80
#       to_port     = 80
#       protocol    = "tcp"
#       cidr_blocks = ["0.0.0.0/0"]
#     }

#     egress {
#       description = "allow all outbound traffic to anywhere on the internet"
#       from_port   = 0
#       to_port     = 0
#       protocol    = "-1"
#       cidr_blocks = ["0.0.0.0/0"]
#     }


#   tags = {
#     Name = "ec2-sg"
#   }
# }

# # create an ec2 instance and deploying it on the public subnet
# resource "aws_instance" "my-ec2" {
#   instance_type               = "t3.micro"
#   subnet_id                   = aws_subnet.public-subnet.id
#   ami                         = "ami-0360c520857e3138f"
#   associate_public_ip_address = true

#   vpc_security_group_ids = [aws_security_group.ec2-sg.id]

#   tags = {
#     Name = "my-ec2"
#   }
# }

# # creating a security group for rds
# resource "aws_security_group" "rds-sg" {
#   name   = "rds-sg"
#   vpc_id = aws_vpc.my-vpc.id

#   ingress {
#       from_port   = 3306
#       to_port     = 3306
#       protocol    = "tcp"
#       description = "allowing traffic only from ec2 instances"
#       security_groups  = [aws_security_group.ec2-sg.id]
#     }

#   tags = {
#     Name = "rds-sg"
#   }
# }

# # creating an rds cluster
# resource "aws_rds_cluster" "my-db-cluster" {
#   cluster_identifier        = "my-rds-cluster"
#   engine                    = "mysql"
#   availability_zones        = ["us-east-1b"]
#   master_username           = "mysql"
#   master_password           = "Omvwsuv200319"
#   db_cluster_instance_class = "db.t3.medium"
#   db_subnet_group_name      = "rds-ec2-db-subnet-group-1"
#   storage_type              = "io2"
#   allocated_storage         = 200

#   vpc_security_group_ids = [aws_security_group.rds-sg.id]

#   tags = {
#     Name = "my-rds-cluster"
#   }
# }

# # create an instance on the cluster
# resource "aws_rds_cluster_instance" "my-db-cluster-instance" {
#   count                = 1
#   cluster_identifier   = aws_rds_cluster.my-db-cluster.id
#   engine               = "mysql"
#   instance_class       = aws_rds_cluster.my-db-cluster.db_cluster_instance_class
#   db_subnet_group_name = aws_rds_cluster.my-db-cluster.db_subnet_group_name
#   publicly_accessible  = true

#   tags = {
#     Name = "my-rds-cluster-db-instance"
#   }
# }
