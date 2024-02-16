data "archive_file" "lambda_zip" {
    type          = "zip"
    source_dir   = "challenges/Furls 2/data/lambda/src/"
    output_path   = "challenges/Furls 2/data/lambda/lambda_function.zip"
}


resource "aws_lambda_function" "auth-me" {
  filename         = "challenges/Furls 2/data/lambda/lambda_function.zip"
  function_name    = "auth-me"
  role             = aws_iam_role.furls2.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "nodejs18.x"

  environment {
    variables = {
      lambda_http_user = "admin",
      lambda_http_password = "NotSummer2023"
      ## FYI non of these are real (there is no api.cloudfoxlabs.com)
      # RDS_HOST    = "payments-${random_string.resource-suffix.result}.c9qjxqjxqjxq.us-east-1.rds.amazonaws.com"
      # RDS_USER    = "admin"
      # RDS_PASSWORD = "d08ejf387p92idjuf"
      # RDS_DB_NAME  = "payments"
      # API_ENDPOINT = "https://api.cloudfoxlabs.com"
      # API_AUTH_TOKEN = "f89ec87sdca6fbb3ec87sdca6fbec87sdca6fbbb"
    }
  }
}

resource "aws_iam_policy" "furls2" {
  name        = "furls2"
  path        = "/"
  description = "Low priv policy used by lambdas"

  # Terraform's "jsonencode" function converts af
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

resource "aws_iam_role" "furls2" {
  name                = "sauerbrunn"
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
  managed_policy_arns = [aws_iam_policy.furls2.arn]
}




resource "aws_lambda_function_url" "furls2" {
  function_name      = aws_lambda_function.auth-me.function_name
  authorization_type = "NONE"
}


// create an iam role called mewis that trusts the ctf-starting-user role to assume it
resource "aws_iam_role" "mewis" {
  name                = "mewis"
  assume_role_policy  = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          AWS = var.ctf_starting_user_arn
        }
      },
    ]
  })
}

// create an iam policy called mewis that allows the user to list lambda functions
resource "aws_iam_policy" "mewis" {
  name        = "mewis"
  path        = "/"
  description = "Low priv policy used by lambdas"

  // Terraform's "jsonencode" function converts a
  // Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [      
      "lambda:ListFunctions",

    ],
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

// attach the mewis policy to the mewis role
resource "aws_iam_role_policy_attachment" "mewis" {
  role       = aws_iam_role.mewis.name
  policy_arn = aws_iam_policy.mewis.arn
}