resource "aws_db_subnet_group" "default" {
  name        = "rds-subnet-group"
  description = "Terraform example RDS subnet group"
  subnet_ids  = [var.subnet1_id, var.subnet2_id, var.subnet3_id]
}


resource "aws_db_instance" "default" {
  allocated_storage    = 5
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  db_name              = "cloudfox${random_string.resource-suffix.result}"  
  identifier           = "cloudfox-rds-${random_string.resource-suffix.result}"   
  username             = "admin"
  password             = random_password.rds-password.result
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  publicly_accessible    = false
  vpc_security_group_ids  = [ var.intra-sg-access-id ]
  db_subnet_group_name = aws_db_subnet_group.default.id

}

data "archive_file" "lambda-rds_zip" {
    type          = "zip"
    source_dir   = "challenges/Variable/data/lambda-src"
    output_path   = "challenges/Variable/data/lambda_function.zip"
}

resource "aws_lambda_function" "rds_sql_executor" {
  filename         = "challenges/Variable/data/lambda_function.zip"
  function_name    = "rds-sql-executor"
  runtime          = "python3.9"
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda-rds_zip.output_base64sha256
  role             = aws_iam_role.lambda_execution_role.arn  
  timeout          = 60

  vpc_config {
    subnet_ids         = [var.subnet1_id, var.subnet2_id]
    security_group_ids = [var.intra-sg-access-id]
  }

  environment {
    variables = {
      RDS_HOST    = aws_db_instance.default.address
      RDS_USER    = aws_db_instance.default.username
      RDS_PASSWORD = aws_db_instance.default.password
      RDS_DB_NAME  = aws_db_instance.default.db_name
    }
  }
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

//add policy to lambda execution role so that it can log to cloudwatch
resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda_policy"
  path        = "/"
  description = "Low priv policy used by lambdas"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ],
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}


resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

// create a null type resource with a local exec provisioner to invoke the lambda
resource "null_resource" "invoke_lambda" {
  triggers = {
    db = aws_db_instance.default.address
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws --region ${var.AWS_REGION} --profile ${var.aws_local_profile} lambda invoke --function-name ${aws_lambda_function.rds_sql_executor.function_name} response.json
    EOT
  }
}


