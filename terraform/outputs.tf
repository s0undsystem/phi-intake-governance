output "api_url" {
  value       = "${aws_apigatewayv2_api.intake.api_endpoint}/intake"
  description = "POST /intake endpoint."
}

output "intake_table" {
  value       = aws_dynamodb_table.intake.name
  description = "DynamoDB table holding patient submissions."
}

output "uploads_bucket" {
  value       = aws_s3_bucket.uploads.id
  description = "S3 bucket where intake attachments land."
}

output "lambda_function_name" {
  value = aws_lambda_function.intake.function_name
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "kms_key_arn" {
  value       = module.grc_baseline.kms_key_arn
  description = "Customer-managed KMS key ARN for PHI data stores."
}

output "evidence_bucket_name" {
  value       = module.grc_baseline.evidence_bucket_name
  description = "S3 evidence vault bucket for signed compliance artifacts."
}

output "cloudtrail_arn" {
  value       = module.grc_baseline.cloudtrail_arn
  description = "Multi-region CloudTrail trail ARN."
}
