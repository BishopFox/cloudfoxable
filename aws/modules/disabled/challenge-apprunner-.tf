resource "aws_apprunner_service" "example" {
  service_name = "apprunner-test"

  source_configuration {
    image_repository {
      image_configuration {
        port = "8000"
        runtime_environment_variables = {
        secret_password = "flag{dont_hardcode_secrets_into_definitions}"
    }
      }
      image_identifier      = "public.ecr.aws/aws-containers/hello-app-runner:latest"
      image_repository_type = "ECR_PUBLIC"
    }
    auto_deployments_enabled = false


}
  tags = {
    Name = "example-apprunner-service"
  }
}

resource "aws_apprunner_service" "cfapprunner-private" {
  service_name = "cfapprunner-private"
 

  source_configuration {
    image_repository {
      image_configuration {
        port = "8000"
      }
      image_identifier      = "${aws_ecr_repository.node-ssrf-app.repository_url}:latest"
      image_repository_type = "ECR"
    }
    authentication_configuration {
      access_role_arn = aws_iam_role.runner_role.arn
    }
  }

  network_configuration {
    ingress_configuration  {
      is_publicly_accessible = false
    }
    egress_configuration  {
      egress_type = "VPC"
      vpc_connector_arn = aws_apprunner_vpc_connector.cf-apprunner-connector.arn
    }
    
  }
  tags = {
    Name = "example-apprunner-service-private"
  }
}

# resource "aws_apprunner_service" "cfapprunner-public" {
#   service_name = "cfapprunner-public"
 

#   source_configuration {
#     image_repository {
#       image_configuration {
#         port = "8000"
#       }
#       image_identifier      = "${aws_ecr_repository.node-ssrf-app.repository_url}:latest"
#       image_repository_type = "ECR"
#     }
#     authentication_configuration {
#       access_role_arn = aws_iam_role.runner_role.arn
#     }
#   }

#   network_configuration {
#     ingress_configuration  {
#       is_publicly_accessible = true
#     }
#     egress_configuration  {
#       egress_type = "VPC"
#       vpc_connector_arn = aws_apprunner_vpc_connector.cf-apprunner-connector.arn
#     }
    
#   }
#   tags = {
#     Name = "example-apprunner-service-public"
#   }
# }



resource "aws_apprunner_vpc_connector" "cf-apprunner-connector" {
  vpc_connector_name = "cf-apprunner-connector"
  subnets            = ["${aws_subnet.cloudfox-operational-1.id}", "${aws_subnet.cloudfox-operational-2.id}"]
  security_groups    = ["${aws_security_group.allow_8000_vpc.id}"]
}

resource "aws_apprunner_vpc_ingress_connection" "cf-apprunner-ingress-connection" {
  name        = "cf-apprunner-ingress-connection"
  service_arn = aws_apprunner_service.cfapprunner-private.arn

  ingress_vpc_configuration {
    vpc_id          = aws_vpc.cloudfox.id
    vpc_endpoint_id = aws_vpc_endpoint.apprunner.id
  }

  tags = {
    foo = "bar"
  }
}

resource "aws_security_group" "allow_8000_vpc" {
  name        = "allow_8000_vpc"
  description = "allow_8000_vpc"
  vpc_id      = aws_vpc.cloudfox.id

  ingress {
    description      = "from this vpc"
    from_port        = 8000
    to_port          = 8000
    protocol         = "tcp"
    cidr_blocks      = ["${aws_subnet.cloudfox-operational-1.cidr_block}", "${aws_subnet.cloudfox-operational-2.cidr_block}"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_8000_vpc"
  }
}



resource "aws_iam_role" "runner_role" {
  name               = "cf-apprunner-role2"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = [
            "build.apprunner.amazonaws.com",
            "apprunner.amazonaws.com",
          ]
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "runner_role_policy_attachment" {
  role       = aws_iam_role.runner_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

resource "aws_vpc_endpoint" "apprunner" {
  vpc_id       = aws_vpc.cloudfox.id
  service_name = "com.amazonaws.${var.AWS_REGION}.apprunner.requests"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.cloudfox-operational-3.id]
  //security_group_ids =  ["${aws_security_group.allow_8000_vpc.id}"]
}