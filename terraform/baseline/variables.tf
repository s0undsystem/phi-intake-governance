variable "name_prefix" {
  type        = string
  description = "Resource name prefix shared with the workload."
}

variable "suffix" {
  type        = string
  description = "Unique suffix for resource names."
}

variable "aws_region" {
  type        = string
  description = "AWS region."
}

variable "account_id" {
  type        = string
  description = "AWS account ID for ARN construction and key policy."
}

variable "uploads_bucket_id" {
  type        = string
  description = "S3 uploads bucket name/ID."
}

variable "uploads_bucket_arn" {
  type        = string
  description = "S3 uploads bucket ARN."
}

variable "intake_table_arn" {
  type        = string
  description = "DynamoDB intake table ARN."
}

variable "lambda_role_id" {
  type        = string
  description = "Lambda execution role ID."
}

variable "lambda_role_name" {
  type        = string
  description = "Lambda execution role name."
}

variable "vpc_id" {
  type        = string
  description = "Existing workload VPC ID."
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block of the workload VPC."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for Lambda and interface endpoints."
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for NAT gateway."
}
