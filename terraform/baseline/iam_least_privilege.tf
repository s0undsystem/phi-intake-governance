resource "aws_iam_role_policy" "lambda_data_access" {
  name = "intake-data-access"
  role = var.lambda_role_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DynamoDBWriteOnly"
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:DescribeTable"
        ]
        Resource = var.intake_table_arn
      },
      {
        Sid    = "S3UploadOnly"
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "${var.uploads_bucket_arn}/uploads/*"
      },
      {
        Sid    = "KMSForPHIData"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.phi.arn
      }
    ]
  })
}
