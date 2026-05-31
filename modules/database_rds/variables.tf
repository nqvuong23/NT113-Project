variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "db_engine" {
  description = "Database engine (mysql or postgres)"
  type        = string
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "db_parameter_group_family" {
  description = "RDS parameter group family (e.g. mysql8.0 or postgres15)"
  type        = string
}

variable "db_allocated_storage" {
  description = "Initial allocated storage in GB"
  type        = number
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage for autoscaling (GB)"
  type        = number
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Master database username"
  type        = string
}

variable "db_password" {
  description = "Master database password"
  type        = string
  sensitive   = true
}

variable "db_backup_retention_days" {
  description = "Number of days to retain automated backups"
  type        = number
}

variable "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  type        = string
}

variable "sg_rds_id" {
  description = "Security Group ID for RDS"
  type        = string
}

variable "kms_key_rds_arn" {
  description = "ARN of the RDS KMS key"
  type        = string
}
