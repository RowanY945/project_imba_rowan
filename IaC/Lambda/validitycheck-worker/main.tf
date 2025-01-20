terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region # Australia region
}

# Use existing role
data "aws_iam_role" "existing_lambda_role" {
  name = "LambdaWebApiRole-DATA15"
}

# Get the Lambda package from S3
data "aws_s3_object" "lambda_package" {
  bucket = "data15-scripts-rowan"
  key    = "lambda/validitycheck-worker/validitycheck-worker.zip"
}

# Lambda Function
resource "aws_lambda_function" "validitycheck-worker" {
  # Use S3 instead of local file
  s3_bucket        = data.aws_s3_object.lambda_package.bucket
  s3_key           = data.aws_s3_object.lambda_package.key
  source_code_hash = data.aws_s3_object.lambda_package.metadata["sha256"]
  
  function_name = "validitycheck-worker"
  role         = data.aws_iam_role.existing_lambda_role.arn
  handler      = "lambda_function.lambda_handler"
  runtime      = "python3.12"
  timeout      = 900
  memory_size  = 128
  architectures = ["x86_64"]
  layers       = ["arn:aws:lambda:ap-southeast-2:336392948345:layer:AWSSDKPandas-Python312:15"]

  ephemeral_storage {
    size = 512
  }
}

# Lambda Function Retry Configuration
resource "aws_lambda_function_event_invoke_config" "validitycheck-worker_retry" {
  function_name                = aws_lambda_function.validitycheck-worker.function_name
  maximum_event_age_in_seconds = 21600
  maximum_retry_attempts       = 2
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.validitycheck-worker.function_name}"
  retention_in_days = 14
}