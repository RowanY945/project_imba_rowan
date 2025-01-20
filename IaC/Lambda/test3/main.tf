terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2" # Australia region
}

# Get the existing IAM role for Lambda
data "aws_iam_role" "existing_lambda_role" {
  name = "LambdaWebApiRole-DATA15"
}

# Get the Lambda package from S3 - this helps us track changes
data "aws_s3_object" "lambda_package" {
  bucket = "data15-scripts-rowan"
  key    = "lambda/test3/test3.zip"  # We organize functions in their own folders
}

# Lambda Function with S3 deployment
resource "aws_lambda_function" "test3" {
  # Instead of local file, we now use S3
  s3_bucket         = data.aws_s3_object.lambda_package.bucket
  s3_key            = data.aws_s3_object.lambda_package.key
  # Use the metadata hash to detect changes
  source_code_hash  = data.aws_s3_object.lambda_package.metadata["sha256"]
  
  function_name    = "test3"
  role            = data.aws_iam_role.existing_lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.12"
  timeout         = 180
  memory_size     = 128
  architectures   = ["x86_64"]

  ephemeral_storage {
    size = 512
  }
}

# Lambda Function Retry Configuration
resource "aws_lambda_function_event_invoke_config" "test3_retry" {
  function_name                = aws_lambda_function.test3.function_name
  maximum_event_age_in_seconds = 21600
  maximum_retry_attempts       = 2
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.test3.function_name}"
  retention_in_days = 14
}
