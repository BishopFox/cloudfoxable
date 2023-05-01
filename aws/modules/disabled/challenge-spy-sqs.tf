resource "aws_iam_role" "event_bridge_sqs_role" {
  name = "robinson"

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
    Name        = "event_bridge_sqs_role"
    Environment = "cloudfox"
  }
}


resource "aws_sqs_queue_policy" "schedule-event-policy" {
  queue_url = aws_sqs_queue.eventbridge_sqs.id

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
      "Resource": "${aws_sqs_queue.eventbridge_sqs.arn}"
    }
  ]
}
POLICY
}


# resource "aws_iam_policy" "eventbridge-sqs-secret-policy" {
#   name        = "eventbridge-sqs-secret-policy"
#   path        = "/"
#   description = ""

#   # Terraform's "jsonencode" function converts a
#   # Terraform expression result to valid JSON syntax.
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect   = "Allow"
#         Action = "ssm:GetParameter"
#         Resource = aws_ssm_parameter.eventbridge-sqs-secret.arn
#       },
#     ]
#   })
# }


# resource "aws_iam_role_policy_attachment" "eventbridge-sqs-secret-policy-attachment" {
#   role       = aws_iam_role.event_bridge_sqs_role.name
#   policy_arn = aws_iam_policy.eventbridge-sqs-secret-policy.arn

# }  

# resource "aws_iam_role_policy_attachment" "eventbridge-sqs-policy-attachment" {
#   role       = aws_iam_role.event_bridge_sqs_role.name
#   policy_arn = aws_iam_policy.schedule-event-policy.arn

# }  




resource "aws_sqs_queue" "eventbridge_sqs" {
  name                      = "eventbridge-sqs"
  delay_seconds             = 0
  max_message_size          = 2048
  message_retention_seconds = 1200
  receive_wait_time_seconds = 5
  tags = {
    Environment = "production"
  }
}


variable "jsonData" {
  type = string
  default = <<JSON
{
     "firstName": "John",
     "lastName": "Smith",
     "age": 25,
     "address":
     {
         "streetAddress": "21 2nd Street",
         "city": "New York",
         "state": "NY",
         "postalCode": "10021"
     },
     "phoneNumber":
     [
         {
           "type": "home",
           "number": "212 555-1234"
         },
         {
           "type": "fax",
           "number": "646 555-4567"
         }
     ],
     "ssn": {FLAG:IveBeenSnoopingOnTheQueuesYo},
 }
JSON
}


# resource "aws_ssm_parameter" "eventbridge-sqs-secret" {
#   name  = "/cloudfoxable/flag/eventbridge-sqs"
#   type  = "SecureString"
#   value = "{FLAG:IveBeenSnoopingOnTheQueuesYo}"

# }

// eventbridge schedule to send message to sqs queue every minute
resource "aws_scheduler_schedule" "test_eventbridge" {
  name                = "test-eventbridge"
  description         = "sends sqs message to queue"
  flexible_time_window {
    mode = "OFF"
  }

schedule_expression = "rate(1 minutes)"

target {
  arn      = aws_sqs_queue.eventbridge_sqs.arn
  role_arn = aws_iam_role.event_bridge_sqs_role.arn


  
  input = var.jsonData
  }
}




