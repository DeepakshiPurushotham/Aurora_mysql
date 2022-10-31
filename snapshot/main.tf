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
}
data "aws_rds_cluster" "aurora-cluster-demo" {
  cluster_identifier = "aurora-cluster-demo"
  tags = {
    "Name" = "test"
  }
}


resource "aws_db_cluster_snapshot" "example" {
  db_cluster_identifier          = data.aws_rds_cluster.aurora-cluster-demo.id
  db_cluster_snapshot_identifier = "demo-snapshot"
  tags = {
    "Name" = "demo-snapshot"
  }
}
