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


data "aws_db_cluster_snapshot" "final_snapshot" {
  db_cluster_identifier = "aurora-cluster-demo"
  most_recent           = true
}
data "aws_db_subnet_group" "database" {
  name = "main"
}

data "aws_security_group" "selected" {
  name = "default-db"
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier   = "aurora-cluster-demo-new"
  snapshot_identifier  = data.aws_db_cluster_snapshot.final_snapshot.id
  engine = data.aws_db_cluster_snapshot.final_snapshot.engine
  engine_version = data.aws_db_cluster_snapshot.final_snapshot.engine_version
  #availability_zones = data.aws_db_cluster_snapshot.final_snapshot.availability_zones
  db_subnet_group_name = data.aws_db_subnet_group.database.name
  vpc_security_group_ids = [data.aws_security_group.selected.id]
  port = 3306
  skip_final_snapshot = true
  master_username         = "admin"
  master_password         = "admin12345678"

  lifecycle {
    ignore_changes = [snapshot_identifier]
  }
}



resource "aws_rds_cluster_instance" "aurora-mysql" {
  count = 2
  cluster_identifier   = aws_rds_cluster.aurora.id
  identifier         = "aurora-cluster-demo-new-${count.index}"
  instance_class       = "db.t3.medium"
  engine = data.aws_db_cluster_snapshot.final_snapshot.engine
  engine_version = data.aws_db_cluster_snapshot.final_snapshot.engine_version
  publicly_accessible = true
  db_subnet_group_name = data.aws_db_subnet_group.database.name
}