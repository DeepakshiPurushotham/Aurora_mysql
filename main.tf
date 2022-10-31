#### Providers Configuration ####
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.34.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}


####### VPC and subnets Creation #######
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "main"
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

resource "aws_eip" "nat" {
  vpc = true

  tags = {
    Name = "nat"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  #subnet_id     = aws_subnet.public-us-east-1a.id 

  tags = {
    Name = "nat"
  }

  depends_on = [aws_internet_gateway.gw]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
 

  route {
      cidr_block                 = "0.0.0.0/0"
      nat_gateway_id             = aws_nat_gateway.nat.id
    }
  

  tags = {
    Name = "private"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
      cidr_block                 = "0.0.0.0/0"
      gateway_id                 = aws_internet_gateway.gw.id
    }
  

  tags = {
    Name = "public"
  }
}

resource "aws_route_table_association" "private-us-east-1a" {
  subnet_id      = aws_subnet.private-us-east-1a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private-us-east-1b" {
  subnet_id      = aws_subnet.private-us-east-1b.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "public-us-east-1a" {
  subnet_id      = aws_subnet.public-us-east-1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public-us-east-1b" {
  subnet_id      = aws_subnet.public-us-east-1b.id
  route_table_id = aws_route_table.public.id
}


############ Subnets ############

resource "aws_subnet" "private-us-east-1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.0/19"
  availability_zone = "us-east-1a"

  tags = {
    "Name"                            = "private-us-east-1a"
  }
}

resource "aws_subnet" "private-us-east-1b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.32.0/19"
  availability_zone = "us-east-1b"

  tags = {
    "Name"                            = "private-us-east-1b"
  }
}

resource "aws_subnet" "public-us-east-1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.64.0/19"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    "Name"                       = "public-us-east-1a"
  }
}

resource "aws_subnet" "public-us-east-1b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.96.0/19"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    "Name"                       = "public-us-east-1b"
  }
}

######## Security Group ############
resource "aws_security_group" "db-sg" {
  name        = "default-db"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "MySQL/Aurora"
    from_port        = 3306            
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.main.cidr_block]
    
  }
  ingress {
    description      = "TLS from VPC"
    from_port        = 0            
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "db-port"
  }
}

####### Db_Subnets_group ########
resource "aws_db_subnet_group" "dbsubnet" {
  name       = "main"
  subnet_ids = [aws_subnet.public-us-east-1a.id, aws_subnet.public-us-east-1b.id]

  tags = {
    Name = "My DB subnet group"
  }
}

######### RDS Cluster ########
resource "aws_rds_cluster" "mysql-cluster" {
  cluster_identifier      = "aurora-cluster-demo"
  engine                  = "aurora-mysql"
  engine_version          = "5.7.mysql_aurora.2.10.2"
  availability_zones      = ["us-east-1a", "us-east-1b"]
  database_name           = "mysqldb"
  master_username         = "admin"
  master_password         = "admin12345678$"
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
  #db_cluster_instance_class = "db.t4g.large"
  #iops = 1000
  #final_snapshot_identifier = "demo"
  #skip_final_snapshot = false
  vpc_security_group_ids = [aws_security_group.db-sg.id ]
  copy_tags_to_snapshot = true
  db_subnet_group_name  = aws_db_subnet_group.dbsubnet.name
  deletion_protection = false
  skip_final_snapshot = true
  port = 3306
  tags = {
    "Name" = "mysql-cluster"
  }
}
resource "aws_rds_cluster_instance" "demo" {
  count = 2
  identifier         = "aurora-cluster-demo-${count.index}"
  cluster_identifier = aws_rds_cluster.mysql-cluster.id
  instance_class     = "db.t3.medium"
  engine             = aws_rds_cluster.mysql-cluster.engine
  engine_version     = aws_rds_cluster.mysql-cluster.engine_version
  publicly_accessible = true
  db_subnet_group_name  = aws_db_subnet_group.dbsubnet.name
}