
resource "aws_iam_user" "ecs-user" {
  name = "james"
  path = "/"
}
resource "aws_iam_access_key" "ecs-user" {
  user = aws_iam_user.ecs-user.name
}

#Iam Role Policy
resource "aws_iam_policy" "challenge-ecs-ssm" {
  name = "bastion-policy"
  description = "bastion-policy"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [        
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "ssm:StartSession",
            "Resource": "${aws_instance.ec2-for-challenge-ecs-ssm.arn}"            
        }
    ]
}
POLICY
}



resource "aws_iam_user_policy_attachment" "challenge-ecs-ssm" {
  user       = aws_iam_user.ecs-user.name
  policy_arn = aws_iam_policy.challenge-ecs-ssm.arn

}  



resource "aws_ecs_cluster" "cloudfox-cluster" {
    name = "cloudfox-cluster"
}


resource "aws_ecs_task_definition" "cloudfox-app" {
  family = "webapp"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  task_role_arn = "${aws_iam_role.cloudfox-ecs-role.arn}"
  execution_role_arn = "${aws_iam_role.shared-ecs-execution-role.arn}"

  container_definitions = <<DEFINITION
[
  {
    "cpu": 128,
    "command": [
            "/bin/sh -c \"echo '<html> <head> <title>CloudFox Test Lab ECS</title> <style>body {margin-top: 40px; background-color: #333;} </style> </head><body> <div style=color:white;text-align:center> <h1>CloudFox Test Lab ECS</h1> </div></body></html>' >  /usr/local/apache2/htdocs/index.html && httpd-foreground\""
         ],
         "entryPoint": [
            "sh",
            "-c"
         ],
    "essential": true,
    "image": "httpd:2.4",
    "memory": 128,
    "memoryReservation": 64,
    "name": "webapp",
    "portMappings": [ 
            { 
               "containerPort": 80,
               "hostPort": 80,
               "protocol": "tcp"
            }
    ],
    "environment": [
          {
              "name": "variable",
              "value": "flag{dont_hardcode_secrets_into_definitions}"
          },
          {
              "name": "AWS_ACCESS_KEY_ID",
              "value": "${aws_iam_access_key.ecs-user.id}"
          },
          {
              "name": "AWS_SECRET_ACCESS_KEY",
              "value": "${aws_iam_access_key.ecs-user.secret}"
          }
      ]
  }
]
DEFINITION
}


data "aws_ecs_task_definition" "cloudfox-app" {
  task_definition = "${aws_ecs_task_definition.cloudfox-app.family}"
}

resource "aws_ecs_service" "cloudfox-app" {
  name          = "cloudfox-app"
  cluster       = "${aws_ecs_cluster.cloudfox-cluster.name}"
  desired_count = 1
  launch_type   = "FARGATE"

 network_configuration  {
    security_groups = [aws_security_group.cloudfox-ecs-http-security-group.id]
    subnets         = ["${aws_subnet.cloudfox-operational-1.id}"]
    assign_public_ip = true
  }

  # Track the latest ACTIVE revision
  task_definition = "${aws_ecs_task_definition.cloudfox-app.family}:${max("${aws_ecs_task_definition.cloudfox-app.revision}", "${data.aws_ecs_task_definition.cloudfox-app.revision}")}"
}


resource "aws_iam_role" "cloudfox-ecs-role" {
  name = "rapinoe"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = {
      Name = "cloudfox-ecs-role"
  }
}
#Iam Role Policy
resource "aws_iam_policy" "cloudfox-ecs-role-policy" {
  name = "cloudfox-ecs-role-policy"
  description = "cloudfox-ecs-role-policy"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeImages",
                "logs:CreateLogStream",
                "ec2:DescribeInstances",
                "ec2:DescribeTags",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:GetAuthorizationToken",
                "ssm:TerminateSession",
                "ec2:DescribeSnapshots",
                "logs:PutLogEvents",
                "ecr:BatchCheckLayerAvailability"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}



resource "aws_iam_policy_attachment" "cloudfox-ecs-role-policy-attachment" {
  name = "cloudfox-ecs-role-policy-attachment"
  roles = [
      "${aws_iam_role.cloudfox-ecs-role.name}"
  ]
  policy_arn = "${aws_iam_policy.cloudfox-ecs-role-policy.arn}"
}


resource "aws_security_group" "cloudfox-ecs-http-security-group" {
  name = "cloudfox-ecs-http"
  description = "Cloudfox Security Group for ecs"
  vpc_id = "${aws_vpc.cloudfox.id}"
  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["${var.user_ip}/32"]
  }
  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["${var.user_ip}/32"]
  }
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = [
          "0.0.0.0/0"
      ]
  }
  tags = {
    Name = "cloudfox-ecs-http"
    Stack = "CloudFox"
  }
}


# data "aws_ami" "amazon-2-ecs-challenge" {
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["amzn2-ami-hvm-*-x86_64-ebs"]
#   }

#   owners = ["amazon"] # Canonical
# }


# resource "aws_instance" "ec2-for-challenge-ecs-ssm" {
#   ami           = data.aws_ami.amazon-2-ecs-challenge.id
#   instance_type = "t3a.nano"
#   subnet_id = aws_subnet.cloudfox-operational-1.id
#   iam_instance_profile = aws_iam_instance_profile.challenge-ecs-ssm.name
#   associate_public_ip_address = true
#   vpc_security_group_ids = [ aws_security_group.cloudfox-ecs-http-security-group.id ]
  
#   tags = {
#     Name = "bastion"
#   }
# }

# resource "aws_iam_role" "role-for-challenge-ecs-ssm" {
#   name                = "reyna"
#   assume_role_policy  = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Sid    = ""
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#       },
#     ]
#   })
# }



# resource "aws_iam_role_policy_attachment" "ssmcore" {
#   role       = aws_iam_role.role-for-challenge-ecs-ssm.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

# }  

# resource "aws_iam_instance_profile" "challenge-ecs-ssm" {
#   name = "challenge-ecs-ssm"
#   role = aws_iam_role.role-for-challenge-ecs-ssm.name
# }
