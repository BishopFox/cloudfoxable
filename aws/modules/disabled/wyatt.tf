data "aws_ami" "amazon-2-ecs" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }

  owners = ["amazon"] # Canonical
}

resource "aws_iam_role" "wyatt-instance-role" {
  name = "wyatt-instance-role"
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
      Name = "wyatt-instance-role"
  }
}

resource "aws_iam_instance_profile" "wyatt-instance-profile" {
  name = "wyatt-instance-profile"
  role = aws_iam_role.wyatt-instance-role.name
}

resource "aws_ecs_cluster" "ecs" {
  name = "wyatt-cluster"
}

resource "aws_launch_configuration" "ecs" {
  name                 = "ecs-launch-config"
  image_id             = data.aws_ami.amazon-2-ecs.id
  instance_type        = "t2.micro"
  security_groups      = [aws_security_group.cloudfox-ecs-ec2-http-security-group-8000.id]
  iam_instance_profile = aws_iam_instance_profile.wyatt-instance-profile.id
  user_data            = "#!/bin/bash\necho ECS_CLUSTER=${aws_ecs_cluster.ecs.name} >> /etc/ecs/ecs.config"


}



resource "aws_autoscaling_group" "ecs" {
  name                      = "ecs-asg"
  launch_configuration      = aws_launch_configuration.ecs.name
  min_size                  = 1
  max_size                  = 1
  desired_capacity          = 1
  vpc_zone_identifier       = [var.subnet1_id]
}

resource "aws_ecs_service" "challenge-wyatt" {
  name          = "challenge-wyatt-service"
  cluster       = "${aws_ecs_cluster.ecs.name}"
  desired_count = 1
  launch_type   = "EC2"

  deployment_controller {
    type = "ECS"
  }

 network_configuration  {
    security_groups = [aws_security_group.cloudfox-ecs-ec2-http-security-group-8000.id]
    subnets         = [var.subnet1_id, var.subnet2_id]
    //assign_public_ip = true
  }

  # Track the latest ACTIVE revision
  task_definition = "${aws_ecs_task_definition.challenge-wyatt.family}:${max("${aws_ecs_task_definition.challenge-wyatt.revision}", "${data.aws_ecs_task_definition.challenge-wyatt.revision}")}"
}

resource "aws_ecs_task_definition" "challenge-wyatt" {
  family = "challenge-wyatt"
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  task_role_arn = "${aws_iam_role.wyatt-task-role.arn}"
  execution_role_arn = "${aws_iam_role.wyatt-task-role.arn}"

//task definition that runs the image sethsec/nodejs-ssrf-app fro docker hub with minimal cpu and memory and listens on port 8000 for incoming https requests
  container_definitions = <<DEFINITION
[
  {
    "cpu": 128,    
    "essential": true,
    "image": "sethsec/nodejs-ssrf-app",
    "memory": 128,
    "name": "challenge-wyatt",
    "portMappings": [ 
            { 
               "containerPort": 8000,
               "hostPort": 12380,
               "protocol": "tcp"
            }
    ]
    
  }
]
DEFINITION
}


data "aws_ecs_task_definition" "challenge-wyatt" {
  task_definition = "${aws_ecs_task_definition.challenge-wyatt.family}"
}




resource "aws_iam_role" "wyatt-task-role" {
  name = "wyatt-task-role"
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
      Name = "wyatt-role"
  }
}


#Iam Role Policy
resource "aws_iam_policy" "wyatt-policy" {
  name = "wyatt-policy"
  description = "wyatt-policy"
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



resource "aws_iam_policy_attachment" "wyatt-policy-attachment" {
  name = "wyatt-policy-attachment"
  roles = [
      "${aws_iam_role.wyatt-task-role.name}",
      "${aws_iam_role.wyatt-instance-role.name}",
      
  ]
  policy_arn = "${aws_iam_policy.wyatt-policy.arn}"
}


resource "aws_iam_role_policy_attachment" "wyatt-policy" {
  role       = aws_iam_role.wyatt-instance-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"

}  

resource "aws_security_group" "cloudfox-ecs-ec2-http-security-group-8000" {
  name = "cloudfox-ecs-ec2-http-8000"
  description = "Cloudfox Security Group for ecs"
  vpc_id = "${var.vpc_id}"
  ingress {
      from_port = 8000
      to_port =  8000
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
      from_port = 0
      to_port = 65535
      protocol = "tcp"
      cidr_blocks = [
          "0.0.0.0/0"
      ]
  }
  tags = {
    Name = "cloudfox-ecs-ec2-http"
    Stack = "CloudFox"
  }
}


