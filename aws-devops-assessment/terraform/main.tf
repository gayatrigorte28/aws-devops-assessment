locals {
  name_prefix = var.project_name
  common_tags = {
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Environment = "assessment"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}
