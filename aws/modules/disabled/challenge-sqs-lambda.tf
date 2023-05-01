resource "aws_iam_role" "event_bridge_sqs_rce_role" {
  name = "event_bridge_sqs_rce_role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "scheduler.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "event_bridge_sqs_rce_role"
    Environment = "cloudfox"
  }
}


resource "aws_sqs_queue_policy" "schedule-event-rce-policy" {
  queue_url = aws_sqs_queue.test_sqs.id

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
      "Resource": "${aws_sqs_queue.test_sqs.arn}"
    }
  ]
}
POLICY
}



resource "aws_iam_role" "lambda-sqs-role" {
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
  managed_policy_arns = [aws_iam_policy.lambda-sqs-policy.arn]
}

resource "aws_iam_policy" "lambda-sqs-policy" {
  name        = "lambda-sqs-policy"
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
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueUrl",
      "sqs:ListQueues",
      "sqs:GetQueueAttributes",
      "sqs:DeleteMessageBatch",
      "sqs:ChangeMessageVisibility",
      "sqs:ChangeMessageVisibilityBatch",
      "sqs:ReceiveMessageBatch",   


    ],
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

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
    ]
  })
}


resource "aws_iam_role_policy_attachment" "lambda-sqs-secret-policy-attachment" {
  role       = aws_iam_role.lambda-sqs-role.name
  policy_arn = aws_iam_policy.lambda-sqs-secret-policy.arn

}  




// lambda to accept sqs messages
resource "aws_lambda_function" "test_lambda_sqs" {
  filename         = "data/challenge-sqs-lambda/lambda_function.zip"
  function_name    = "lambda-sqs"
  role             = aws_iam_role.lambda-sqs-role.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.lambda_sqs_zip.output_base64sha256
  runtime          = "nodejs14.x"
}

// add trigger assocition to sqs queue
resource "aws_lambda_event_source_mapping" "test_lambda_sqs_mapping" {
  event_source_arn = aws_sqs_queue.test_sqs.arn
  function_name    = aws_lambda_function.test_lambda_sqs.arn
  batch_size       = 1
  enabled          = true
}

data "archive_file" "lambda_sqs_zip" {
    type          = "zip"
    source_file   = "data/challenge-sqs-lambda/src/index.js"
    output_path   = "data/challenge-sqs-lambda/lambda_function.zip"
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

// sqs queue that sends messages to a lambda function
resource "aws_sqs_queue" "test_sqs" {
  name                      = "lambda-sqs"
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






resource "aws_ssm_parameter" "lambda-sqs-secret" {
  name  = "/cloudfoxable/flag/lambda-sqs"
  type  = "SecureString"
  value = "{FLAG:queuesCanBeInterestingToo}"
}


// eventbridge schedule to send message to sqs queue every minute
resource "aws_scheduler_schedule" "eventbridge_sqs_rce" {
  name                = "eventbridge_sqs_rce"
  description         = "sends sqs message to queue"
  flexible_time_window {
    mode = "OFF"
  }

schedule_expression = "rate(2 minutes)"

target {
  arn      = aws_sqs_queue.test_sqs.arn
  role_arn = aws_iam_role.event_bridge_sqs_rce_role.arn


  
  input = "echo \"hello world\" > /tmp/hello.txt"
  
  }
}
