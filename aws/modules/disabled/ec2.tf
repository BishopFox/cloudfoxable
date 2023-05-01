data "aws_ami" "amazon-2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }

  owners = ["amazon"] # Canonical
}

resource "aws_security_group" "allow_ssh_from_world" {
  name        = "allow_ssh_from_world"
  description = "Allow SSH inbound traffic from world"
  vpc_id      = aws_vpc.cloudfox.id

  ingress {
    description      = "SSH from world"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh_from_world"
  }
}


resource "aws_instance" "ec2-1" {
  ami           = data.aws_ami.amazon-2.id
  instance_type = "t3.medium"
  subnet_id = aws_subnet.cloudfox-operational-1.id
  iam_instance_profile = aws_iam_instance_profile.cf_profile.name
  associate_public_ip_address = true
  vpc_security_group_ids = [ aws_security_group.allow_ssh_from_world.id ]
  
  tags = {
    Name = "instance1"
  }
}

resource "aws_iam_role" "ec2-ssm" {
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
  role       = aws_iam_role.ec2-ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

}  

resource "aws_iam_role_policy_attachment" "auditor" {
  role       = aws_iam_role.ec2-ssm.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"

}  

resource "aws_iam_instance_profile" "cf_profile" {
  name = "cf-profile"
  role = aws_iam_role.ec2-ssm.name
}

resource "aws_iam_policy" "ec2-1-s3getObject" {
  name        = "ec2-1-s3getObject"
  path        = "/"
  description = "ec2-1-s3getObject"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.cloudfox-bucket1.arn}/*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2-1-s3getObject-attach-policy" {
  role       = aws_iam_role.ec2-ssm.name
  policy_arn = aws_iam_policy.ec2-1-s3getObject.arn

}  

# resource "aws_instance" "ec2-2" {
#   ami           = data.aws_ami.amazon-2.id
#   instance_type = "t3.nano"
#   subnet_id = aws_subnet.cloudfox-operational-1.id
#   #iam_instance_profile = "service-admin-profile"
#   associate_public_ip_address = true
#   vpc_security_group_ids = [ aws_security_group.allow_ssh_from_world.id ]
  
#   tags = {
#     Name = "instance2"
#   }
# }

# resource "aws_instance" "ec2-3" {
#   ami           = data.aws_ami.amazon-2.id
#   instance_type = "t3.nano"
#   subnet_id = aws_subnet.cloudfox-operational-1.id
#   iam_instance_profile = "service-admin-profile"
#   associate_public_ip_address = true
#   vpc_security_group_ids = [ aws_security_group.allow_ssh_from_world.id ]
  
#   tags = {
#     Name = "instance3"
#   }
# }

# resource "aws_instance" "ec2-4" {
#   ami           = data.aws_ami.amazon-2.id
#   instance_type = "t3.nano"
#   subnet_id = aws_subnet.cloudfox-operational-1.id
#   #iam_instance_profile = "service-admin-profile"
#   associate_public_ip_address = true
#   vpc_security_group_ids = [ aws_security_group.allow_ssh_from_world.id ]
#   user_data = <<EOF
# #!/bin/bash
# export RDS_USER="admin"
# export RDS_PASSWORD="${random_password.database-secret.result}"
#   EOF
#   user_data_replace_on_change = true
#   tags = {
#     Name = "instance4"
#   }
# }


# resource "aws_iam_policy" "just-one-ec2" {
#   name        = "just-one-ec2"
#   path        = "/"
#   description = "just-one-ec2"

#   # Terraform's "jsonencode" function converts a
#   # Terraform expression result to valid JSON syntax.
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect   = "Allow"
#         Action = "ec2:DescribeInstanceAttributeInput"
#         Resource = "arn:aws:ec2:us-east-1:${var.account_id}:instance/${aws_instance.ec2-4.id}"
#       },
#     ]
#   })
# }


# resource "aws_iam_role" "just-one-ec2" {
#   name                = "morgan"
#   assume_role_policy  = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Sid    = ""
#         Principal = {
#           AWS = aws_iam_user.pele.arn
#         }
#       },
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "just-one-ec2-role-attach-policy" {
#   role       = aws_iam_role.just-one-ec2.name
#   policy_arn = aws_iam_policy.just-one-ec2.arn

# }  



# resource "aws_elb" "bar" {
# 	name               = "cloudfox-elb"
#   subnets = [ aws_subnet.cloudfox-operational-1.id ]
# 	# access_logs {
# 	#   bucket        = "foo"
# 	#   bucket_prefix = "bar"
# 	#   interval      = 60
# 	# }
  
# 	listener {
# 	  instance_port     = 8000
# 	  instance_protocol = "http"
# 	  lb_port           = 80
# 	  lb_protocol       = "http"
# 	}
  
	
  
# 	health_check {
# 	  healthy_threshold   = 2
# 	  unhealthy_threshold = 2
# 	  timeout             = 3
# 	  target              = "HTTP:8000/"
# 	  interval            = 30
# 	}
  
# 	instances                   = [aws_instance.ec2-3.id]
# 	cross_zone_load_balancing   = true
# 	idle_timeout                = 400
# 	connection_draining         = true
# 	connection_draining_timeout = 400
  
# 	tags = {
# 	  Name = "cloudfox-elb"
# 	}
#   }


  