


resource "aws_ecs_task_definition" "challenge-ecs-ssrf" {
  family = "challenge-ecs-ssrf"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  task_role_arn = "${aws_iam_role.cloudfox-ecs-ssrf-role.arn}"
  execution_role_arn = "${aws_iam_role.shared-ecs-execution-role.arn}"

//task definition that runs the image sethsec/nodejs-ssrf-app fro docker hub with minimal cpu and memory and listens on port 8000 for incoming https requests
  container_definitions = <<DEFINITION
[
  {
    "cpu": 128,    
    "essential": true,
    "image": "sethsec/nodejs-ssrf-app",
    "memory": 128,
    "name": "challenge-ecs-ssrf",
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




data "aws_ecs_task_definition" "challenge-ecs-ssrf" {
  task_definition = "${aws_ecs_task_definition.challenge-ecs-ssrf.family}"
}

resource "aws_ecs_service" "challenge-ecs-ssrf" {
  name          = "challenge-ecs-ssrf-service"
  cluster       = "${aws_ecs_cluster.cloudfox-cluster.name}"
  desired_count = 1
  launch_type   = "FARGATE"

 network_configuration  {
    security_groups = [aws_security_group.cloudfox-ecs-http-security-group-8000.id]
    subnets         = ["${aws_subnet.cloudfox-operational-1.id}"]
    assign_public_ip = true
  }

  # Track the latest ACTIVE revision
  task_definition = "${aws_ecs_task_definition.challenge-ecs-ssrf.family}:${max("${aws_ecs_task_definition.challenge-ecs-ssrf.revision}", "${data.aws_ecs_task_definition.challenge-ecs-ssrf.revision}")}"
}


resource "aws_iam_role" "cloudfox-ecs-ssrf-role" {
  name = "ecs-ssrf-role"
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
resource "aws_iam_policy" "cloudfox-ecs-ssrf-role-policy" {
  name = "cloudfox-ecs-ssrf-role-policy"
  description = "cloudfox-ecs-ssrf-role-policy"
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



resource "aws_iam_policy_attachment" "cloudfox-ecs-ssrf-role-policy-attachment" {
  name = "cloudfox-ecs-ssrf-role-policy-attachment"
  roles = [
      "${aws_iam_role.cloudfox-ecs-role.name}"
  ]
  policy_arn = "${aws_iam_policy.cloudfox-ecs-ssrf-role-policy.arn}"
}


resource "aws_security_group" "cloudfox-ecs-http-security-group-8000" {
  name = "cloudfox-ecs-http-8000"
  description = "Cloudfox Security Group for ecs"
  vpc_id = "${aws_vpc.cloudfox.id}"
  ingress {
      from_port = 8000
      to_port = 8000
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