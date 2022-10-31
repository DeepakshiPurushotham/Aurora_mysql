data "aws_db_cluster_snapshot" "final_snapshot" {
  db_cluster_identifier = var.db_cluster_identifier
  most_recent           = true
}
data "aws_db_subnet_group" "database" {
  name = var.aws_db_subnet_group
}

data "aws_security_group" "selected" {
  name = var.aws_security_group
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier   = var.cluster_identifier
  snapshot_identifier  = data.aws_db_cluster_snapshot.final_snapshot.id
  engine = data.aws_db_cluster_snapshot.final_snapshot.engine
  engine_version = data.aws_db_cluster_snapshot.final_snapshot.engine_version
  #availability_zones = data.aws_db_cluster_snapshot.final_snapshot.availability_zones
  db_subnet_group_name = data.aws_db_subnet_group.database.name
  vpc_security_group_ids = [data.aws_security_group.selected.id]
  port = 3306
  skip_final_snapshot = true
  master_username         = var.master_username
  master_password         = var.master_password

  lifecycle {
    ignore_changes = [snapshot_identifier]
  }
}



resource "aws_rds_cluster_instance" "aurora-mysql" {
  count = 2
  cluster_identifier   = aws_rds_cluster.aurora.id
  identifier         = var.cluster_identifier[count.index]
  instance_class       = var.instance_class 
  engine = data.aws_db_cluster_snapshot.final_snapshot.engine
  engine_version = data.aws_db_cluster_snapshot.final_snapshot.engine_version
  publicly_accessible = true
  db_subnet_group_name = data.aws_db_subnet_group.database.name
}