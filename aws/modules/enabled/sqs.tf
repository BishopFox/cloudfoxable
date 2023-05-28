// This is just extra stuff to make the hunt a little more realistic 
// (also includes a public queue that has no integrations which means the public config has no risk)


resource "aws_sqs_queue" "queue" {
  name                      = "queue"
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

resource "aws_sqs_queue" "fifo" {
  name                        = "fefifofum.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
}


resource "aws_sqs_queue" "process_orders" {
  name                      = "process_orders"
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
  queue_url = aws_sqs_queue.process_orders.id

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
      "Resource": "${aws_sqs_queue.process_orders.arn}"      
    }
  ]
}
POLICY 
}

