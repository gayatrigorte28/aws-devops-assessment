variable "aws_region" {
  description = "AWS region for this environment"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Short project identifier used in resource names"
  type        = string
  default     = "devops-assessment"
}

variable "vpc_cidr" {
  description = "CIDR range for the VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "enable_nat_gateway" {
  description = "Create NAT Gateway and private-subnet default routes; may incur charges"
  type        = bool
  default     = false
}

variable "enable_compute" {
  description = "Create Launch Template and Auto Scaling Group; may incur charges"
  type        = bool
  default     = false
}

variable "enable_alb" {
  description = "Create Application Load Balancer; may incur charges"
  type        = bool
  default     = false
}

variable "enable_database" {
  description = "Create RDS MySQL and a Secrets Manager secret; may incur charges"
  type        = bool
  default     = false
}

variable "enable_https" {
  description = "Add HTTPS listener; requires an ACM certificate ARN"
  type        = bool
  default     = false
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN in the same region as the ALB"
  type        = string
  default     = ""
}

variable "allowed_http_cidr" {
  description = "CIDR allowed to reach the demo ALB on HTTP; narrow this before deployment"
  type        = string
  default     = "0.0.0.0/0"
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_username" {
  type    = string
  default = "appadmin"
}
