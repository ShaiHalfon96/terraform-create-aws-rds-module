variable "identifier" {
    description = "Database identifier"
    type        = string
}
variable "username" {
    description = "Database username to create"
    type        = string
    default = "admin"
}
variable "password" {
    description = "Database master user password"
    type        = string
    sensitive   = true
}
variable "max_allocated_storage" {
    description = "Upper limit to which Amazon RDS can automatically scale the storage of the DB instance."
    type        = number
    default     = 20
}
variable "engine" {
    description = "Database engine"
    type        = string
    default     = "mysql"
}

variable "engine_version" {
    description = "Database engine version"
    type        = string
    default     = "8.0.35"
}

variable "instance_class" {
    description = "Database instance class"
    type        = string
    default     = "db.t4g.large"
}
variable "storage_type" {
    description = "The storage type for the RDS instance (gp2/gp3)"
    type        = string
    default     = "gp2"
    validation {
        condition     = var.storage_type == "gp2" || var.storage_type == "gp3"
        error_message = "storage_type must be either 'gp2' or 'gp3'"
    }
}

variable "backup_retention_period" {
  description = "The number of days to retain automated backups"
  type        = number
  default     = 7 

  validation {
    condition     = var.backup_retention_period >= 1 && var.backup_retention_period <= 30
    error_message = "backup_retention_period must be between 1 and 30 days"
  }
}

variable "vpc_id" {
  description = "The ID of the vpc where the db will be created"
  type        = string
}
variable "subnet_ids" {
  description = "Existing subnet ids associated with the VPC"
  type        = list
}
variable "ingress_security_groups" {
  description = "List of groups can be used relative to the RDS"
  type        = list(string)
  default     = []
}
variable "read_replicas" {
  description = "Number of read replicas"
  type        = number
  default     = 0
  validation {
    condition     = var.read_replicas >= 0 && var.read_replicas <= 5
    error_message = "read_replica must be between 0 and 5 replicas"
  }

}