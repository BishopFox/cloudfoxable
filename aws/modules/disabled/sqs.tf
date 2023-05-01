resource "aws_sqs_queue" "terraform_queue" {
  name                      = "terraform-example-queue"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
#   redrive_policy = jsonencode({
#     deadLetterTargetArn = aws_sqs_queue.terraform_queue_deadletter.arn
#     maxReceiveCount     = 4
#  })

  tags = {
    Environment = "production"
  }
}

resource "aws_sqs_queue" "terraform_queue_fifo" {
  name                        = "terraform-example-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
}


resource "aws_sqs_queue" "public_queue" {
  name                      = "public_queue"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
#   redrive_policy = jsonencode({
#     deadLetterTargetArn = aws_sqs_queue.terraform_queue_deadletter.arn
#     maxReceiveCount     = 4
#  })

  tags = {
    Environment = "production"
  }
}

resource "aws_sqs_queue_policy" "public_queue_policy" {
  queue_url = aws_sqs_queue.public_queue.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "terraform_queue",
  "Statement": [
    {
      "Sid": "terraform_queue",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.terraform_queue.arn}"      
    }
  ]
}
POLICY 
}

