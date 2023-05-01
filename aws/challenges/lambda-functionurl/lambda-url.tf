resource "aws_iam_policy" "lambda-policy1" {
  name        = "lambda-policy1"
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


resource "aws_iam_policy" "lambda-policy2" {
  name        = "lambda-policy2"
  path        = "/"
  description = "High priv policy used by lambdas"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "*"
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# Source: https://gist.github.com/smithclay/e026b10980214cbe95600b82f67b4958
# Simple AWS Lambda Terraform Example

data "archive_file" "lambda_zip" {
    type          = "zip"
    source_file   = "challenges/lambda-functionurl/data/lambda/src/index.js"
    output_path   = "challenges/lambda-functionurl/data/lambda/lambda_function.zip"
}


resource "aws_lambda_function" "test_lambda2" {
  filename         = "challenges/lambda-functionurl/data/lambda/lambda_function.zip"
  function_name    = "lambda2"
  role             = aws_iam_role.lambda-role2.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "nodejs12.x"
}


resource "aws_iam_role" "lambda-role1" {
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
  managed_policy_arns = [aws_iam_policy.lambda-policy1.arn]
}


resource "aws_iam_role" "lambda-role2" {
  name                = "adams"
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
  managed_policy_arns = [aws_iam_policy.lambda-policy2.arn]
}


resource "aws_lambda_function_url" "lambda2-url" {
  function_name      = aws_lambda_function.test_lambda2.function_name
  authorization_type = "NONE"
}



