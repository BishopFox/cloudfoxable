provider "aws" {
  region = "us-east-1"
}

# Create Starting Role and Permissions
resource "aws_iam_role" "double_tap" {
  name = "double_tap"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          AWS = "*"
        }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "double_tap_iam_policy" {
  name        = "double_tap_iam_policy"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["lambda:CreateFunction", "iam:PassRole"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "double_tap_iam_policy_attachment" {
  policy_arn = aws_iam_policy.double_tap_iam_policy.arn
  role       = aws_iam_role.double_tap.name
}

resource "aws_iam_policy" "lambda_ec2_policy" {
  name        = "lambda_ec2_policy"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ec2:*"
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/double_tap1" = "true"
          }
        }
      }
    ]
  })
}


resource "aws_iam_role" "lambda_ec2" {
  name = "lambda_ec2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_ec2_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  role       = aws_iam_role.lambda_ec2.name
}

# Configure EC2
resource "aws_iam_policy" "ec2_privileged_policy" {
  name        = "ec2_privileged_policy"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ssm:*"
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/double_tap2" = "true"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role" "ec2_privileged" {
  name = "ec2_privileged"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_privileged_policy" {
  policy_arn = aws_iam_policy.ec2_privileged_policy.arn
  role       = aws_iam_role.ec2_privileged.name
}

resource "aws_instance" "ec2" {
  ami           = "ami-0ff8a91507f77f867"
  instance_type = "t2.micro"
  iam_instance_profile = "${aws_iam_instance_profile.ec2_privileged_profile.name}"
  tags = {
    double_tap1  = "true"
  }
}

resource "aws_iam_instance_profile" "ec2_privileged_profile" {
  name = "ec2_privileged_profile"
  role = aws_iam_role.ec2_privileged.name
}

# Create flag
resource "aws_instance" "flag" {
  ami           = "ami-0ff8a91507f77f867"
  instance_type = "t2.micro"
  tags = {
    double_tap2  = "true"
  }

  user_data = <<-EOF
              #!/bin/bash
              echo 'Starting SSM agent installation...'
              sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
              echo 'SSM agent installation complete.'
              echo 'Starting SSM agent...'
              sudo systemctl start amazon-ssm-agent
              echo 'SSM agent started.'
              echo "test" > /root/flag.txt
              EOF
}
