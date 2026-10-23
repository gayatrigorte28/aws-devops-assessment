resource "aws_db_subnet_group" "main" {
  count      = var.enable_database ? 1 : 0
  name       = "${local.name_prefix}-db-subnets"
  subnet_ids = aws_subnet.private_db[*].id
  tags       = local.common_tags
}

resource "aws_secretsmanager_secret" "db" {
  count                   = var.enable_database ? 1 : 0
  name                    = "${local.name_prefix}/database"
  recovery_window_in_days = 7
  tags                    = local.common_tags
}

resource "random_password" "db" {
  count            = var.enable_database ? 1 : 0
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret_version" "db" {
  count     = var.enable_database ? 1 : 0
  secret_id = aws_secretsmanager_secret.db[0].id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db[0].result
    engine   = "mysql"
    dbname   = var.db_name
  })
}

resource "aws_db_instance" "main" {
  count                  = var.enable_database ? 1 : 0
  identifier             = "${local.name_prefix}-mysql"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp3"
  db_name                = var.db_name
  username               = var.db_username
  password               = random_password.db[0].result
  db_subnet_group_name   = aws_db_subnet_group.main[0].name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
  storage_encrypted      = true
  skip_final_snapshot    = true
  deletion_protection    = false
  backup_retention_period = 1
  tags                   = local.common_tags
}
