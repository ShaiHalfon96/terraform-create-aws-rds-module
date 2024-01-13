#create a security group for RDS Database Instance
resource "aws_security_group" "mysql_sg" {
  name = "${var.identifier}_rds"
  description = "Security group for MySQL RDS instance"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port       = local.engine_default_port[var.engine]
    to_port         = local.engine_default_port[var.engine]
    protocol        = "tcp"
    security_groups = "${var.ingress_security_groups}"
  }
}

resource "aws_iam_role" "rds_monitoring_role" {
  name = "${var.identifier}-rds-monitoring-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "cloudwatch_full_access_attachment" {
  name = "cloudwatch-full-access-attachment"
  roles = [aws_iam_role.rds_monitoring_role.name]
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

resource "aws_db_subnet_group" "default" {
  name       = "${var.identifier}-subnet-group"
  subnet_ids = "${var.subnet_ids}"

  tags = {
    Name = "${var.identifier} DB subnet group"
  }
}

resource "aws_db_option_group" "option_group" {
  name        = "${local.option_group_name}"
  option_group_description = "Terraform Option Group"
  engine_name              = "mysql"
  major_engine_version     = "${local.major_version}"
}

#create a RDS Database Instance
resource "aws_db_instance" "primary_instance" {
  engine                              = "${var.engine}"
  identifier                          = "${var.identifier}"
  max_allocated_storage               = "${var.max_allocated_storage}"
  allocated_storage                   = 20 # Initial storage allocation will be ignored automatically when Storage Autoscaling occurs
  engine_version                      = "${var.engine_version}"
  instance_class                      = "${var.instance_class}"
  storage_type                        = "${var.storage_type}"  # Specify the storage type (gp2/gp3)
  username                            = "${var.username}"
  password                            = "${var.password}"
  db_subnet_group_name                = aws_db_subnet_group.default.name
  vpc_security_group_ids              = [aws_security_group.mysql_sg.id]
  skip_final_snapshot                 = false
  publicly_accessible                 = false
  option_group_name                   = "${local.option_group_name}"
  multi_az                            = true  # Enable Multi-AZ deployment for high availability

  backup_retention_period             = "${var.backup_retention_period}" 
  backup_window                       = "22:00-04:00"  # The daily time range (in UTC)
  
  iam_database_authentication_enabled = true
  monitoring_interval                 = 30
  monitoring_role_arn                 = aws_iam_role.rds_monitoring_role.arn
  
  depends_on                          = [aws_db_option_group.option_group]
}

resource "aws_db_instance" "read_replica" {
  count                  = min(var.read_replicas, length(data.aws_availability_zones.available.names))
  replicate_source_db    = aws_db_instance.primary_instance.identifier
  vpc_security_group_ids = [aws_security_group.mysql_sg.id]
  availability_zone      = element(data.aws_availability_zones.available.names, count.index)
  backup_window          = "22:00-04:00"  # The daily time range (in UTC)
  instance_class         = "${var.instance_class}"
  option_group_name      = "${local.option_group_name}"
  depends_on             = [aws_db_instance.primary_instance]
  skip_final_snapshot    = true
}