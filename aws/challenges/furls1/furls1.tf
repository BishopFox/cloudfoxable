data "archive_file" "lambda_zip" {
    type          = "zip"
    source_file   = "challenges/furls1/data/lambda/src/index.js"
    output_path   = "challenges/furls1/data/lambda/lambda_function.zip"
}


resource "aws_lambda_function" "furls1" {
  filename         = "challenges/furls1/data/lambda/lambda_function.zip"
  function_name    = "furls1"
  role             = aws_iam_role.furls1.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "nodejs14.x"
}


resource "aws_iam_policy" "furls1" {
  name        = "furls1"
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


resource "aws_iam_role" "furls1" {
  name                = "aaronson"
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
  managed_policy_arns = [aws_iam_policy.furls1.arn]
}


resource "aws_lambda_function_url" "furls1" {
  function_name      = aws_lambda_function.furls1.function_name
  authorization_type = "NONE"
}



