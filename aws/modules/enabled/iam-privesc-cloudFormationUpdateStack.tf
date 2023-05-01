resource "aws_iam_policy" "cloudformation" {
  name        = "cloudformation"
  path        = "/"
  description = "Allows privesc via cloudformation:UpdateStack"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
	 "Version": "2012-10-17",
	 "Statement": [
	   {
		 "Sid": "VisualEditor0",
		 "Effect": "Allow",
		 "Action": [
			 "cloudformation:UpdateStack",
			 "cloudformation:DescribeStacks"
		 ],
		 "Resource": "*"
	  }
   ]
})
}

resource "aws_iam_role" "cloudformation-role" {
  name                = "mckennie"
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

# resource "aws_iam_user" "cloudformation-user" {
#   name = "cloudformation-user"
#   path = "/"
# }

# resource "aws_iam_access_key" "cloudformation-user" {
#   user = aws_iam_user.cloudformation-user.name
# }


# resource "aws_iam_user_policy_attachment" "cloudformation-user-attach-policy" {
#   user       = aws_iam_user.cloudformation-user.name
#   policy_arn = aws_iam_policy.cloudformation.arn
# }

resource "aws_iam_role_policy_attachment" "cloudformation-role-attach-policy" {
  role       = aws_iam_role.cloudformation-role.name
  policy_arn = aws_iam_policy.cloudformation.arn
}
