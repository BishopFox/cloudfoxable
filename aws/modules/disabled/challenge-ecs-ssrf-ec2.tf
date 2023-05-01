data "aws_ami" "amazon-2-ecs" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }

  owners = ["amazon"] # Canonical
}

resource "aws_iam_role" "ecs-ec2-ssrf-instance-role" {
  name = "ecs-ec2-ssrf-instance-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = {
      Name = "ecs-ec2-ssrf-instance-role"
  }
}

resource "aws_iam_instance_profile" "ecs-ec2-ssrf-instance-profile" {
  name = "ecs-ec2-ssrf-instance-profile"
  role = aws_iam_role.ecs-ec2-ssrf-instance-role.name
}

resource "aws_ecs_cluster" "ecs" {
  name = "ecs-ec2-ssrf-cluster"
}

resource "aws_launch_configuration" "ecs" {
  name                 = "ecs-launch-config"
  image_id             = data.aws_ami.amazon-2-ecs.id
  instance_type        = "t2.micro"
  security_groups      = [aws_security_group.cloudfox-ecs-ec2-http-security-group-8000.id]
  iam_instance_profile = aws_iam_instance_profile.ecs-ec2-ssrf-instance-profile.id
  user_data            = "#!/bin/bash\necho ECS_CLUSTER=${aws_ecs_cluster.ecs.name} >> /etc/ecs/ecs.config"


}



resource "aws_autoscaling_group" "ecs" {
  name                      = "ecs-asg"
  launch_configuration      = aws_launch_configuration.ecs.name
  min_size                  = 1
  max_size                  = 1
  desired_capacity          = 1
  vpc_zone_identifier       = [aws_subnet.cloudfox-operational-1.id, aws_subnet.cloudfox-operational-2.id]
}

resource "aws_ecs_service" "challenge-ecs-ec2-ssrf" {
  name          = "challenge-ecs-ec2-ssrf-service"
  cluster       = "${aws_ecs_cluster.ecs.name}"
  desired_count = 1
  launch_type   = "EC2"

  deployment_controller {
    type = "ECS"
  }

 network_configuration  {
    security_groups = [aws_security_group.cloudfox-ecs-ec2-http-security-group-8000.id]
    subnets         = ["${aws_subnet.cloudfox-operational-1.id}"]
    //assign_public_ip = true
  }

  # Track the latest ACTIVE revision
  task_definition = "${aws_ecs_task_definition.challenge-ecs-ec2-ssrf.family}:${max("${aws_ecs_task_definition.challenge-ecs-ec2-ssrf.revision}", "${data.aws_ecs_task_definition.challenge-ecs-ec2-ssrf.revision}")}"
}

resource "aws_ecs_task_definition" "challenge-ecs-ec2-ssrf" {
  family = "challenge-ecs-ec2-ssrf"
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  task_role_arn = "${aws_iam_role.ecs-ec2-ssrf-task-role.arn}"
  execution_role_arn = "${aws_iam_role.shared-ecs-execution-role.arn}"

//task definition that runs the image sethsec/nodejs-ssrf-app fro docker hub with minimal cpu and memory and listens on port 8000 for incoming https requests
  container_definitions = <<DEFINITION
[
  {
    "cpu": 128,    
    "essential": true,
    "image": "sethsec/nodejs-ssrf-app",
    "memory": 128,
    "name": "challenge-ecs-ec2-ssrf",
    "portMappings": [ 
            { 
               "containerPort": 8000,
               "hostPort": 8000,
               "protocol": "tcp"
            }
    ]
    
  }
]
DEFINITION
}


data "aws_ecs_task_definition" "challenge-ecs-ec2-ssrf" {
  task_definition = "${aws_ecs_task_definition.challenge-ecs-ec2-ssrf.family}"
}




resource "aws_iam_role" "ecs-ec2-ssrf-task-role" {
  name = "ecs-ec2-ssrf-task-role"
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
      Name = "ecs-ec2-ssrf-role"
  }
}


#Iam Role Policy
resource "aws_iam_policy" "ecs-ec2-ssrf-policy" {
  name = "ecs-ec2-ssrf-policy"
  description = "ecs-ec2-ssrf-policy"
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



resource "aws_iam_policy_attachment" "ecs-ec2-ssrf-policy-attachment" {
  name = "ecs-ec2-ssrf-policy-attachment"
  roles = [
      "${aws_iam_role.ecs-ec2-ssrf-task-role.name}",
      "${aws_iam_role.ecs-ec2-ssrf-instance-role.name}",
      
  ]
  policy_arn = "${aws_iam_policy.ecs-ec2-ssrf-policy.arn}"
}


resource "aws_iam_role_policy_attachment" "ecs-ec2-ssrf-policy" {
  role       = aws_iam_role.ecs-ec2-ssrf-instance-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"

}  

resource "aws_security_group" "cloudfox-ecs-ec2-http-security-group-8000" {
  name = "cloudfox-ecs-ec2-http-8000"
  description = "Cloudfox Security Group for ecs"
  vpc_id = "${aws_vpc.cloudfox.id}"
  ingress {
      from_port = 8000
      to_port = 8000
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
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
    Name = "cloudfox-ecs-ec2-http"
    Stack = "CloudFox"
  }
}
