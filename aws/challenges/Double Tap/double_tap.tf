# Configure EC2
resource "aws_security_group" "instance_sg" {
  name        = "instance_sg"
  description = "Security group for EC2 instance"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "ami" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
  owners = ["amazon"] 
}

# Create flag
resource "aws_secretsmanager_secret" "double_tap_flag_secret" {
  name = "DT_flag"
  recovery_window_in_days = 0
}

# Configure flag secret
resource "aws_secretsmanager_secret_version" "double_tap_flag_secret_version" {
  secret_id     = aws_secretsmanager_secret.double_tap_flag_secret.id
  secret_string = "FLAG{double_tap::ExploitChainsAreFun}"
}

resource "aws_iam_policy" "double_tap_secret_policy" {
  name        = "double_tap_secret_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds",
          "secretsmanager:ListSecrets"
        ]
        Effect   = "Allow"
        Resource = [
          aws_secretsmanager_secret.double_tap_flag_secret.arn
        ]
      }
    ]
  })
}
// role that gets applied to second instance - the one that can get the flag
resource "aws_iam_role" "double_tap_secret" {
  name = "double_tap_secret"

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

resource "aws_iam_role_policy_attachment" "double_tap_secret_policy" {
  policy_arn = aws_iam_policy.double_tap_secret_policy.arn
  role       = aws_iam_role.double_tap_secret.name
}

resource "aws_iam_role_policy_attachment" "ssm_ec2_secret_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.double_tap_secret.name
}

resource "aws_iam_policy" "double_tap_deny_ssm_parameter_access" {
  name        = "double_tap_deny_ssm_parameter_access-bastion"
  path        = "/"
  description = "IAM policy to deny access to certain SSM permissions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Deny"
        Action   = [
          "ssm:GetParameter",
          "ssm:GetParameters",
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "double-tap-deny" {
  role       = aws_iam_role.double_tap_secret.name
  policy_arn = aws_iam_policy.double_tap_deny_ssm_parameter_access.arn

}  






resource "aws_instance" "flag" {
  ami           = data.aws_ami.ami.id
  instance_type = "t3a.nano"
  iam_instance_profile = "${aws_iam_instance_profile.double_tap_secret_profile.name}"  
  security_groups = ["instance_sg"]
  tags = {
    double_tap2  = "true",
    Name = "double_tap"
  }

  # user_data = <<-EOF
  #             #!/bin/bash
  #             echo 'Starting SSM agent installation...'
  #             sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
  #             echo 'SSM agent installation complete.'
  #             echo 'Starting SSM agent...'
  #             sudo systemctl start amazon-ssm-agent
  #             echo 'SSM agent started.'
  #             EOF
}

resource "aws_iam_instance_profile" "double_tap_secret_profile" {
  name = "double_tap_secret_profile"
  role = aws_iam_role.double_tap_secret.name
}

# Create first hop
resource "aws_iam_policy" "ec2_privileged_policy" {
  name        = "ec2_privileged_policy"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            "Effect": "Allow",
            "Action": ["ssm:StartSession"],
            "Resource": "*",
            "Condition": {"StringEquals": {"aws:ResourceTag/double_tap2" = "true"}}
        },
        {
            "Effect": "Deny",
            "Action": ["ec2:DeleteTags", "ec2:CreateTags"],
            "Resource": "*"
        },
        {
         "Effect": "Allow",
         "Action": "ssm:*",
         "Resource": "arn:aws:ssm:*:*:*"
        },
        {
         "Effect":"Allow",
         "Action":["ssm:SendCommand"],
         "Resource":["arn:aws:ec2:*:*:instance/*"],
         "Condition": {"StringEquals": {"aws:ResourceTag/double_tap2" = "true"}}
        }
    ]
  })
}

// the role that gets applied to the first instance
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

# resource "aws_iam_role_policy_attachment" "ssm_ec2_priv_policy_attachment" {
#   role       = aws_iam_role.ec2_privileged.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }

resource "aws_instance" "ec2" {

  ami           = data.aws_ami.ami.id
  instance_type = "t3a.nano"
  iam_instance_profile = "${aws_iam_instance_profile.ec2_privileged_profile.name}"
  security_groups = ["instance_sg"]

  tags = {
    double_tap1  = "true",
    Name = "double_tap"
  }
}

resource "aws_iam_instance_profile" "ec2_privileged_profile" {
  name = "ec2_privileged_profile"
  role = aws_iam_role.ec2_privileged.name
}






# Create Starting Role and Permissions

resource "aws_iam_role" "double_tap_xsdf" {
  name = "double_tap_xsdf"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          "AWS": "${var.ctf_starting_user_arn}"
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
      Action   = ["lambda:CreateFunction", "lambda:InvokeFunction"]
      Resource = "*"
    },
    {
      Effect   = "Allow"
      Action   = ["iam:PassRole"]
      Resource = "arn:aws:iam::${var.account_id}:role/lambda_*"
    }
    ],
    
  })
}

resource "aws_iam_role_policy_attachment" "double_tap_iam_policy_attachment" {
  policy_arn = aws_iam_policy.double_tap_iam_policy.arn
  role       = aws_iam_role.double_tap_xsdf.name
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
  policy_arn = aws_iam_policy.lambda_ec2_policy.arn
  role       = aws_iam_role.lambda_ec2.name
}

resource "aws_iam_role_policy_attachment" "lambda_ec2_read_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
  role       = aws_iam_role.lambda_ec2.name
}


## dead end roles

resource "aws_iam_role" "double_tap_asdf" {
  name = "double_tap_asdf"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          "AWS": "${var.ctf_starting_user_arn}"
        }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role" "double_tap_esdf" {
  name = "double_tap_esdf"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          "AWS": "${var.ctf_starting_user_arn}"
        }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role" "double_tap_qsdf" {
  name = "double_tap_qsdf"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          "AWS": "${var.ctf_starting_user_arn}"
        }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role" "double_tap_zsdf" {
  name = "double_tap_zsdf"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          "AWS": "${var.ctf_starting_user_arn}"
        }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}
