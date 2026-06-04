output "kms_key_arn" {
  value       = aws_kms_key.phi.arn
  description = "Customer-managed KMS key ARN for PHI data stores."
}

output "kms_key_id" {
  value       = aws_kms_key.phi.key_id
  description = "Customer-managed KMS key ID."
}

output "lambda_security_group_id" {
  value       = aws_security_group.lambda.id
  description = "Security group for VPC-attached Lambda."
}

output "evidence_bucket_name" {
  value       = aws_s3_bucket.evidence.id
  description = "S3 evidence vault bucket name."
}

output "evidence_bucket_arn" {
  value       = aws_s3_bucket.evidence.arn
  description = "S3 evidence vault bucket ARN."
}

output "cloudtrail_arn" {
  value       = aws_cloudtrail.phi.arn
  description = "CloudTrail trail ARN."
}

output "cloudtrail_name" {
  value       = aws_cloudtrail.phi.name
  description = "CloudTrail trail name."
}
