// the following lambda function will send messages to sqs

data "archive_file" "producer_zip" {
    type          = "zip"
    source_file   = "challenges/middle/data/lambda/producer/lambda_function.py"
    output_path   = "challenges/middle/data/lambda/producer/lambda_function.zip"
}


// lambda to sned sqs messages
resource "aws_lambda_function" "producer" {
  filename         = "challenges/middle/data/lambda/producer/lambda_function.zip"
  function_name    = "producer"
  role             = aws_iam_role.producer.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.producer_zip.output_base64sha256
  runtime = "python3.10"
  environment {
    variables = {
      "TARGET_SQS_QUEUE_NAME" = aws_sqs_queue.internal_message_bus.id
    }
  }
}

resource "aws_iam_role" "producer" {
  name                = "producer"
  assume_role_policy  = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

// add an iam policy that will allow the lambda to send message to cloudwatch
resource "aws_iam_policy" "producer" {
  name        = "producer"
  path        = "/"
  description = "Low priv policy used by lambdas"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [      
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ],
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

// attach the policy to the role
resource "aws_iam_role_policy_attachment" "producer" {
  role       = aws_iam_role.producer.name
  policy_arn = aws_iam_policy.producer.arn
}



// add add an iam policy that will only allow lambda:getfunction to this lambda above (so that the user can see the code)
resource "aws_iam_policy" "lambda-viewer" {
  name        = "lambda-viewer"
  path        = "/"
  description = "this guy can read a lambda function"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [      
      "lambda:GetFunction"
    ],
        Effect   = "Allow"
        Resource = aws_lambda_function.producer.arn
      },
    ]
  })
}

// create an iam role that trusts the ctf-starting-user iam user to assume it
resource "aws_iam_role" "pepi" {
  name               = "pepi"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCTFStartingUserAssumeRole",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${var.ctf_starting_user_arn}"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

// attach the policy to the role

resource "aws_iam_role_policy_attachment" "lambda-viewer" {
  role       = aws_iam_role.pepi.name
  policy_arn = aws_iam_policy.lambda-viewer.arn
}




// sqs queue that sends messages to a lambda function
resource "aws_sqs_queue" "internal_message_bus" {
  name                      = "internal_message_bus"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.terraform_queue_deadletter.arn
    maxReceiveCount     = 4
 })

  tags = {
    Environment = "production"
  }
}


resource "aws_sqs_queue" "terraform_queue_deadletter" {
  name                      = "terraform-example-queue-deadletter"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10

  tags = {
    Environment = "production"
  }
}



resource "aws_sqs_queue_policy" "schedule-event-rce-policy" {
  queue_url = aws_sqs_queue.internal_message_bus.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "First",
      "Effect": "Allow",
      "Principal": "*",
      "Action": ["sqs:SendMessage", "sqs:ReceiveMessage"],
      "Resource": "${aws_sqs_queue.internal_message_bus.arn}"
    }
  ]
}
POLICY
}



resource "aws_iam_role" "consumer" {
  name                = "swanson"
  assume_role_policy  = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = [aws_iam_policy.lambda-sqs-secret-policy.arn]
}

# resource "aws_iam_policy" "producer" {
#   name        = "producer"
#   path        = "/"
#   description = "Low priv policy used by lambdas"

#   # Terraform's "jsonencode" function converts a
#   # Terraform expression result to valid JSON syntax.
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [      
#       "logs:CreateLogGroup",
#       "logs:CreateLogStream",
#       "logs:PutLogEvents",
#       "sqs:DeleteMessage",
#       "sqs:GetQueueUrl",
#       "sqs:ListQueues",
#       "sqs:GetQueueAttributes",
#       "sqs:DeleteMessageBatch",
#       "sqs:ChangeMessageVisibility",
#       "sqs:ChangeMessageVisibilityBatch"
#     ],
#         Effect   = "Allow"
#         Resource = aws_sqs_queue.internal_message_bus.arn
#       },
#     ]
#   })
# }

resource "aws_iam_policy" "lambda-sqs-secret-policy" {
  name        = "lambda-sqs-secret-policy"
  path        = "/"
  description = ""

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action = "ssm:GetParameter"
        Resource = aws_ssm_parameter.lambda-sqs-secret.arn
      },
      {
        Effect   = "Allow"
        Action = [
                    "sqs:ReceiveMessage",
                    "sqs:DeleteMessage",
                    "sqs:GetQueueUrl",
                    "sqs:GetQueueAttributes",
                    "sqs:ChangeMessageVisibility",
                    "sqs:ChangeMessageVisibilityBatch",
                    "sqs:DeleteMessageBatch"
        ]                    
        Resource = aws_sqs_queue.internal_message_bus.arn
      },
      {
        Effect   = "Allow"
        Action = [
                    "logs:CreateLogGroup",
                    "logs:CreateLogStream",
                    "logs:PutLogEvents"
        ]                    
        Resource = "*"
      }
    ]
  })
}



# resource "aws_iam_role_policy_attachment" "lambda-sqs-secret-policy-attachment" {
#   role       = aws_iam_role.consumer.name
#   policy_arn = aws_iam_policy.lambda-sqs-secret-policy.arn

# }  




# // lambda to accept sqs messages
# resource "aws_lambda_function" "test_lambda_sqs" {
#   filename         = "data/challenge-sqs-lambda/lambda_function.zip"
#   function_name    = "lambda-sqs"
#   role             = aws_iam_role.lambda-sqs-role.arn
#   handler          = "index.handler"
#   source_code_hash = data.archive_file.lambda_sqs_zip.output_base64sha256
#   runtime          = "nodejs14.x"
# }


data "archive_file" "consumer_zip" {
    type          = "zip"
    source_file   = "challenges/middle/data/lambda/consumer/lambda_function.py"
    output_path   = "challenges/middle/data/lambda/consumer/lambda_function.zip"
}


// lambda to consume sqs messages
resource "aws_lambda_function" "consumer" {
  filename         = "challenges/middle/data/lambda/consumer/lambda_function.zip"
  function_name    = "consumer"
  role             = aws_iam_role.consumer.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.producer_zip.output_base64sha256
  runtime = "python3.10"
  environment {
    variables = {
      "TARGET_SQS_QUEUE_NAME" = aws_sqs_queue.internal_message_bus.id
    }
  }
}


// add trigger assocition to sqs queue
resource "aws_lambda_event_source_mapping" "consumer_mapping" {
  event_source_arn = aws_sqs_queue.internal_message_bus.arn
  function_name    = aws_lambda_function.consumer.arn
  batch_size       = 1
  enabled          = true
}

# data "archive_file" "lambda_sqs_zip" {
#     type          = "zip"
#     source_file   = "data/challenge-sqs-lambda/src/index.js"
#     output_path   = "data/challenge-sqs-lambda/lambda_function.zip"
# }






resource "aws_ssm_parameter" "lambda-sqs-secret" {
  name  = "/cloudfoxable/flag/lambda-sqs"
  type  = "SecureString"
  value = "{FLAG:middle::queuesCanBeInterestingToo}"
}


# // eventbridge schedule to send message to sqs queue every minute
# resource "aws_scheduler_schedule" "eventbridge_sqs_rce" {
#   name                = "eventbridge_sqs_rce"
#   description         = "sends sqs message to queue"
#   flexible_time_window {
#     mode = "OFF"
#   }

# schedule_expression = "rate(2 minutes)"

# target {
#   arn      = aws_sqs_queue.internal_message_bus.arn
#   role_arn = aws_iam_role.event_bridge_sqs_rce_role.arn


  
#   input = "echo \"hello world\" > /tmp/hello.txt"
  
#   }
# }



