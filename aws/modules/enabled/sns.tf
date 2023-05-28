resource "aws_sns_topic" "user_updates" {
  name = "user-updates-topic" 
}

resource "aws_sns_topic" "user_updates-fifo" {
  name                        = "user-updates-topic.fifo"
  fifo_topic                  = true
  content_based_deduplication = true
}




// create an sns topic that allows anyone from account 1111111111111 to send messages to the topic
resource "aws_sns_topic_policy" "user_updates" {
  arn = aws_sns_topic.user_updates.arn

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "user_updates",
  "Statement": [
    {
      "Sid": "user_updates",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "sns:Publish",
      "Resource": "${aws_sns_topic.user_updates.arn}",
      "Condition": {
        "StringEquals": {
          "AWS:SourceOwner": "111111111111"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_sns_topic" "important_updates" {
  name = "public" 
}


resource "aws_sns_topic_policy" "important_updates" {
  arn = aws_sns_topic.important_updates.arn

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "public",
  "Statement": [
    {
      "Sid": "public",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "sns:Publish",
      "Resource": "${aws_sns_topic.important_updates.arn}"      
    }
  ]
}
POLICY
}
