# Create step function role
provider "aws" {
  region = var.aws_region
}

resource "aws_iam_role" "lambda_invocation_role" {
  name = "lambda-invocation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_invocation_policy" {
  name = "StepFunctionsLambdaRole-DATA15"
  role = aws_iam_role.lambda_invocation_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          "arn:aws:lambda:ap-southeast-2:863518414180:function:calculate-worker-configs",
          "arn:aws:lambda:ap-southeast-2:863518414180:function:job-validity-checker",
          "arn:aws:lambda:ap-southeast-2:863518414180:function:job-collector"
        ]
      }
    ]
  })
}
