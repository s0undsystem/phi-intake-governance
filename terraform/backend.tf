terraform {
  backend "s3" {
    bucket         = "phi-intake-governance-tfstate"
    key            = "patient-intake-api/terraform.tfstate"
    region         = "us-east-1"
    use_lockfile   = true
    encrypt        = true
  }
}
