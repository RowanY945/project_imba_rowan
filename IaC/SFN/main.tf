provider "aws" {
  region = var.aws_region
}

resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "ValidityChecker-state-machine"
  role_arn = var.sfn_policy_name
  definition = <<EOF
{
  "Comment": "Job Validation Pipeline with Dynamic Workers",
  "StartAt": "CalculateConfigs",
  "States": {
    "CalculateConfigs": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:ap-southeast-2:863518414180:function:calculate-worker-configs",
      "Next": "ParallelWorkers",
      "ResultPath": "$.configs",
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
          ],
          "IntervalSeconds": 30,
          "MaxAttempts": 3,
          "BackoffRate": 2
        }
      ]
    },
    "ParallelWorkers": {
      "Type": "Map",
      "ItemsPath": "$.configs.worker_configs",
      "MaxConcurrency": 0,
      "Next": "Collector",
      "ResultPath": "$.worker_results",
      "Iterator": {
        "StartAt": "Worker",
        "States": {
          "Worker": {
            "Type": "Task",
            "Resource": "arn:aws:lambda:ap-southeast-2:863518414180:function:job-validity-checker",
            "End": true,
            "Retry": [
              {
                "ErrorEquals": [
                  "Lambda.ServiceException",
                  "Lambda.AWSLambdaException",
                  "Lambda.SdkClientException"
                ],
                "IntervalSeconds": 30,
                "MaxAttempts": 3,
                "BackoffRate": 2
              }
            ]
          }
        }
      }
    },
    "Collector": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:ap-southeast-2:863518414180:function:job-collector",
      "End": true,
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
          ],
          "IntervalSeconds": 30,
          "MaxAttempts": 3,
          "BackoffRate": 2
        }
      ]
    }
  }
}
EOF
}