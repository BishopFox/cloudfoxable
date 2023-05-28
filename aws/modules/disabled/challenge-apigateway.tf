# Create an IAM role for the Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

data "archive_file" "apigateway-lambda" {
    type        = "zip"
    source_file  = "data/challenge-apigateway-lambda/src/index.js"
    output_path = "data/challenge-apigateway-lambda/ctf_lambda.zip"
}


# Create a Lambda function that prints the CTF flag
resource "aws_lambda_function" "ctf_lambda" {
  function_name = "apigateway-lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs14.x"
  filename      = "data/challenge-apigateway-lambda/ctf_lambda.zip"
  source_code_hash = data.archive_file.apigateway-lambda.output_base64sha256
}

# Create an IAM policy that allows the user to invoke the API Gateway
resource "aws_iam_policy" "execute_api_policy" {
  name        = "execute-api-policy"
  description = "Allow execute-api:Invoke"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "execute-api:Invoke"
        Resource = "*"
      }
    ]
  })
}

# Create an IAM user and attach the execute-api policy
resource "aws_iam_user" "api_user" {
  name = "api-user"
}

resource "aws_iam_user_policy_attachment" "execute_api_policy_attachment" {
  user       = aws_iam_user.api_user.name
  policy_arn = aws_iam_policy.execute_api_policy.arn
}


# Create a security group that allows incoming traffic from within the VPC
resource "aws_security_group" "allow_vpc_traffic" {
  name        = "allow-vpc-traffic"
  description = "Allow incoming traffic from within the VPC"
  vpc_id      = aws_vpc.cloudfox.id
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.cloudfox.cidr_block]
  }
}

# Create an API Gateway with VPC links
resource "aws_api_gateway_rest_api" "example" {
  name        = "example-api"
  description = "Example API Gateway with VPC links"
  body = <<EOF
{
  "openapi": "3.0.1",
  "info": {
    "title": "CTF Flag API",
    "version": "1.0.0"
  },
  "paths": {
    "/v1/flag": {
      "get": {
        "summary": "Retrieve the CTF flag",
        "operationId": "getFlag",
        "responses": {
          "200": {
            "description": "Successful operation",
            "content": {
              "application/json": {
                "schema": {
                  "type": "object",
                  "properties": {
                    "flag": {
                      "type": "string"
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
EOF
        


  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = "execute-api:Invoke"
        Resource = "execute-api:/*"
        Condition = {
          IpAddress = {
            "aws:SourceIp" = "${var.user_ip}/32"
          }
        }
      }
    ]
  })    
    endpoint_configuration {
        types = ["PRIVATE"]
    }
}

resource "aws_api_gateway_resource" "example" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  parent_id   = aws_api_gateway_rest_api.example.root_resource_id
  path_part   = "flag"
}

resource "aws_api_gateway_method" "example" {
  rest_api_id   = aws_api_gateway_rest_api.example.id
  resource_id   = aws_api_gateway_resource.example.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "example" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  resource_id = aws_api_gateway_resource.example.id
  http_method = aws_api_gateway_method.example.http_method
  type        = "AWS_PROXY"
  integration_http_method = "GET"
  uri = aws_lambda_function.ctf_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "example" {
  depends_on  = [
    aws_api_gateway_integration.example,
    aws_api_gateway_method.example
  ]
  rest_api_id = aws_api_gateway_rest_api.example.id
  stage_name = "v1"
}


resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ctf_lambda.arn
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.example.execution_arn}/*/*"
}

# resource "aws_api_gateway_vpc_link" "this" {
#   name        = "example-vpc-link"
#   description = "Example VPC link for API Gateway"
#   target_arns = [aws_lb.example.arn]
# }

resource "aws_api_gateway_stage" "example" {
  stage_name    = "v1"
  rest_api_id   = aws_api_gateway_rest_api.example.id
  deployment_id = aws_api_gateway_deployment.example.id
#   variables = {
#     vpcLinkId = aws_api_gateway_vpc_link.this.id
#   }

}


# resource "aws_lb" "example" {
#   name               = "example-lb"
#   internal           = true
#   load_balancer_type = "network"
#   subnets            = [aws_subnet.cloudfox-operational-1.id]
# }

