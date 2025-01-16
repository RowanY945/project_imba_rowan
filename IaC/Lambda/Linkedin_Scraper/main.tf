terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"  # Australia region
}

# Use existing role
data "aws_iam_role" "existing_lambda_role" {
  name = "LambdaWebApiRole-DATA15"
}

# Lambda Function
resource "aws_lambda_function" "linkedin_scraper" {
  filename         = "${path.module}/../../../scripts/lambda/linkedin_scraper.zip"
  function_name    = "linkedinscraper22"
  role            = data.aws_iam_role.existing_lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.12"
  timeout         = 180
  memory_size     = 128

  ephemeral_storage {
    size = 512
  }

  environment {
    variables = {
      ACCOUNT1_EMAIL        = "ron87190@gmail.com"
      ACCOUNT2_EMAIL        = "data15group3@gmail.com"
      ACCOUNT3_EMAIL        = "elizkoko07@gmail.com"
      SEARCH_LIMIT         = "5"
      JOB_DECORATION_ID    = "com.linkedin.voyager.deco.jobs.web.shared.WebFullJobPosting-65"
      SLEEP_TIME_MIN       = "2"
      SEARCH_LOCATION      = "Australia"
      LINKEDIN_COOKIES_KEY = "data15group3-cookies"
      NUMBER_OF_PAGES      = "1"
      LISTED_AT           = "86400"
      SLEEP_TIME_MAX      = "4"
      LINKEDIN_DATALAKE_KEY = "data15group3-job-data-lake"
      ACCOUNT1_COOKIE_FILE = "ron87190@gmail.com.jr"
      ACCOUNT2_COOKIE_FILE = "data15group3@gmail.com.jr"
      ACCOUNT3_COOKIE_FILE = "elizkoko07@gmail.com.jr"
    }
  }
}

# Lambda Function Retry Configuration
resource "aws_lambda_function_event_invoke_config" "linkedin_scraper_retry" {
  function_name                = aws_lambda_function.linkedin_scraper.function_name
  maximum_event_age_in_seconds = 21600
  maximum_retry_attempts       = 2
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.linkedin_scraper.function_name}"
  retention_in_days = 14
}
