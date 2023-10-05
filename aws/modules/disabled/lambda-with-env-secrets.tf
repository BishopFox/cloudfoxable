# data "archive_file" "lambda_env_zip" {
#     type          = "zip"
#     source_file   = "data/challenge-lambda-secret/index.js"
#     output_path   = "data/challenge-lambda-secret/lambda_function.zip"
# }

# resource "aws_lambda_function" "cloudfox-lambda" {
#   filename         = "data/challenge-lambda-secret/lambda_function.zip"
#   function_name    = "cloudfox-lambda"
#   role             = aws_iam_role.lambda-env-role.arn
#   handler          = "lambda_function.lambda_handler"
#   source_code_hash = filebase64sha256("data/challenge-lambda-secret/lambda_function.zip")
#   runtime          = "nodejs18.x"
#   timeout          = 60
#   memory_size      = 128
#   publish          = true
#   tags = {
#     Name = "cloudfox-lambda"
#   }
#   environment {
#     variables = {
#       RDS_HOST    = "payments-${random_string.resource-suffix.result}.c9qjxqjxqjxq.us-east-1.rds.amazonaws.com"
#       RDS_USER    = "admin"
#       RDS_PASSWORD = "d08ejf387p92idjuf"
#       RDS_DB_NAME  = "payments"
#       API_ENDPOINT = "https://api.cloudfoxlabs.com"
#       API_AUTH_TOKEN = "f89ec87sdca6fbb3ec87sdca6fbec87sdca6fbbb"
#   }
# }
# }

# resource "aws_iam_role" "lambda-env-role" {
#   name                = "lambda-env-role"
#   assume_role_policy  = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Sid    = ""
#         Principal = {
#           Service = "lambda.amazonaws.com"
#         }
#       },
#     ]
#   })
#   managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
# }