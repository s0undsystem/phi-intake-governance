data "aws_caller_identity" "current" {}

locals {
  intake_table_arn   = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${local.name_prefix}-submissions-${local.suffix}"
  uploads_bucket_arn = "arn:aws:s3:::${local.name_prefix}-uploads-${local.suffix}"
}

module "grc_baseline" {
  source = "./baseline"

  name_prefix        = local.name_prefix
  suffix             = local.suffix
  aws_region         = var.aws_region
  account_id         = data.aws_caller_identity.current.account_id
  uploads_bucket_id  = aws_s3_bucket.uploads.id
  uploads_bucket_arn = local.uploads_bucket_arn
  intake_table_arn   = local.intake_table_arn
  lambda_role_id     = aws_iam_role.lambda.id
  lambda_role_name   = aws_iam_role.lambda.name
  vpc_id             = aws_vpc.main.id
  vpc_cidr           = aws_vpc.main.cidr_block
  private_subnet_ids = aws_subnet.private[*].id
  public_subnet_ids  = aws_subnet.public[*].id
}
