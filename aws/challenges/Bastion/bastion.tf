
data "aws_ami" "bastion" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }

  owners = ["amazon"] 
}


resource "aws_security_group" "intra-sg-access" {
  name        = "intra-sg-access"
  description = "intra-sg-access"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "intra-sg-access"
  }
}

resource "aws_security_group_rule" "intra-sg-access-ingress" {
  security_group_id = aws_security_group.intra-sg-access.id

  type        = "ingress"
  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  self        = true
}

output "intra-sg-access-id" {
  value = aws_security_group.intra-sg-access.id
}

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.bastion.id
  instance_type = "t3a.nano"
  subnet_id = var.subnet1_id
  iam_instance_profile = aws_iam_instance_profile.bastion.name
  associate_public_ip_address = true
  vpc_security_group_ids = [ aws_security_group.intra-sg-access.id ]
  
  tags = {
    Name = "bastion"
  }
}

resource "aws_iam_role" "bastion" {
  name                = "reyna"
  assume_role_policy  = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}



resource "aws_iam_role_policy_attachment" "ssmcore" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

}  

resource "aws_iam_policy" "rootdeny_ssm_parameter_access" {
  name        = "rootdeny_ssm_parameter_access-bastion"
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

resource "aws_iam_role_policy_attachment" "bastion-deny" {
  role       = aws_iam_role.bastion.name
  policy_arn = aws_iam_policy.rootdeny_ssm_parameter_access.arn

}  


resource "aws_iam_instance_profile" "bastion" {
  name = "bastion"
  role = aws_iam_role.bastion.name
}


// create a policy that allows the bastion to list and download the contents of an S3 bucket called cloudfoxable-bastion-RANDOMSTRING
resource "aws_iam_policy" "bastion-s3" {
  name = "bastion-s3"
  description = "Allows the bastion to list and download the contents of the S3 bucket with flag"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::cloudfoxable-bastion-${random_string.resource-suffix.result}",
          "arn:aws:s3:::cloudfoxable-bastion-${random_string.resource-suffix.result}/*",
        ]
      },
      {
      Action = [
        "s3:ListAllMyBuckets",
      ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::*",                
    ]
      }
    ]
  })
}

// attach the policy to the bastion
resource "aws_iam_role_policy_attachment" "bastion-s3" {
  role       = aws_iam_role.bastion.name
  policy_arn = aws_iam_policy.bastion-s3.arn
}

resource "aws_s3_bucket" "cloudfoxable-bastion" {
  bucket = "cloudfoxable-bastion-${random_string.resource-suffix.result}"
    force_destroy = true


  tags = {
    Name        = "cloudfoxable-bastion-${random_string.resource-suffix.result}"
  }
}

# resource "aws_s3_bucket_acl" "cloudfoxable-bastion-acl" {
#   bucket = aws_s3_bucket.cloudfoxable-bastion.id
#   acl    = "private"
# }

resource "aws_s3_bucket_public_access_block" "cloudfoxable-bastion-public-access-block" {
  bucket = aws_s3_bucket.cloudfoxable-bastion.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

// upload a file to the bucket.
resource "aws_s3_object" "cloudfoxable-bastion-object" {
  bucket = aws_s3_bucket.cloudfoxable-bastion.id
  key    = "flag.txt"
  source = "./challenges/Bastion/data/flag.txt"
}

// create a policy that will allow the ctf starting user to ssm:startsession to the bastion
resource "aws_iam_policy" "bastion-ssm" {
  name = "bastion-ssm"
  description = "Allows the ctf starting user to ssm:startsession to the bastion"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:StartSession",
          "ssm:SendCommand",
          "ssm:ListCommandInvocations",
          "ssm:TerminateSession",
        ]
        Effect = "Allow"
        Resource = [
          aws_instance.bastion.arn,
        ]
      },
    ]
  })
}

// attach the policy to the ctf starting user
resource "aws_iam_user_policy_attachment" "bastion-ssm" {
  user       = var.ctf_starting_user_name
  policy_arn = aws_iam_policy.bastion-ssm.arn
}

