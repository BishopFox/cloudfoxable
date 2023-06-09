resource "aws_iam_role" "event_bridge_sns_role" {
  name = "spy-sns-role"

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
    Name        = "event_bridge_sns_role"
    Environment = "cloudfox"
  }
}


resource "aws_sns_topic_policy" "schedule-event-policy" {
  arn = aws_sns_topic.eventbridge_sns.arn

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "snspolicy",
  "Statement": [
    {
      "Sid": "First",
      "Effect": "Allow",
      "Principal": "*",
      "Action": ["sns:Subscribe", "sns:Publish"],
      "Resource": "${aws_sns_topic.eventbridge_sns.arn}",
      "Condition": {
          "IpAddress": {
            "aws:SourceIp": "${var.user_ip}/32"
          }
        }
    }
  ]
}
POLICY
}


resource "aws_sns_topic" "eventbridge_sns" {
  name = "eventbridge-sns"
  tags = {
    Environment = "production"
  }
}


variable "jsonDataSNS" {
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
     "ssn": FLAG{the-topic-is-exposure::IveBeenReadingUpOnTopics},
 }
JSON
}


// eventbridge schedule to send message to sns topic every minute
resource "aws_scheduler_schedule" "test_eventbridge-sns" {
  name                = "test-eventbridge-sns"
  description         = "sends sns message to topic"
  flexible_time_window {
    mode = "OFF"
  }

schedule_expression = "rate(1 minutes)"

target {
  arn      = aws_sns_topic.eventbridge_sns.arn
  role_arn = aws_iam_role.event_bridge_sns_role.arn


  
  input = var.jsonDataSNS
  }
}





# // create an iam user and access key for that user with no permissions
# resource "aws_iam_user" "eventbridge_user" {
#   name = "eventbridge-user"
#   tags = {
#     Name        = "eventbridge-user"
#     Environment = "cloudfox"
#   }
# }

# // create aws iam access keys for the eventbridge_user
# resource "aws_iam_access_key" "eventbridge_user" {
#   user = aws_iam_user.eventbridge_user.name
# }



