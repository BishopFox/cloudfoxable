resource "aws_iam_policy" "ssmStartSession-policy" {
  name        = "ssmStartSession-policy"
  path        = "/"
  description = "Allows privesc via targeted ssm"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ssm:StartSession",
          "ssm:SendCommand",
          "iam:CreateAccessKey",
           "ssm:DescribeSessions",
            "ssm:GetConnectionStatus",
            "ssm:DescribeInstanceProperties",
            "ssm:TerminateSession",
            "ssm:ResumeSession"
        ]
        Resource = "*"
      },
    ]
  })
}



resource "aws_iam_role" "ssmStartSession-role" {
  name                = "dempsey"
  assume_role_policy  = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          AWS = var.aws_assume_role_arn
        }
      },
    ]
  })
}


# resource "aws_iam_user" "ssmStartSession-user" {
#   name = "ssmStartSession-user"
#   path = "/"
# }

# resource "aws_iam_access_key" "ssmStartSession-user" {
#   user = aws_iam_user.ssmStartSession-user.name
# }



# resource "aws_iam_user_policy_attachment" "ssmStartSession-user-attach-policy" {
#   user       = aws_iam_user.ssmStartSession-user.name
#   policy_arn = aws_iam_policy.ssmStartSession-policy.arn
# }


resource "aws_iam_role_policy_attachment" "ssmStartSession-role-attach-policy" {
  role       = aws_iam_role.ssmStartSession-role.name
  policy_arn = aws_iam_policy.ssmStartSession-policy.arn

}  

