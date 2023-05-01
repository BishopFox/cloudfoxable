resource "aws_iam_policy" "lambda" {
  name        = "lambda"
  path        = "/"
  description = "Allows privesc via lambda:UpdateFunctionCode"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "lambda-role" {
  name                = "donovan"
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

# resource "aws_iam_user" "lambda-user" {
#   name = "lambda-user"
#   path = "/"
# }

# resource "aws_iam_access_key" "lambda-user" {
#   user = aws_iam_user.lambda-user.name
# }


# resource "aws_iam_user_policy_attachment" "lambda-user-attach-policy" {
#   user       = aws_iam_user.lambda-user.name
#   policy_arn = aws_iam_policy.lambda.arn
# }

resource "aws_iam_role_policy_attachment" "lambda-role-attach-policy" {
  role       = aws_iam_role.lambda-role.name
  policy_arn = aws_iam_policy.lambda.arn
}
