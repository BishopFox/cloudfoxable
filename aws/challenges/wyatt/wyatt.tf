data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "wyatt" {
  ami           = data.aws_ami.amazon_linux.id
  security_groups = [aws_security_group.wyatt.id ]
  vpc_security_group_ids = [ aws_security_group.wyatt.id ]
  iam_instance_profile = aws_iam_instance_profile.wyatt.name

  instance_type = "t3a.nano"
  subnet_id = var.subnet1_id
  user_data = <<-EOF
                #!/bin/bash
                yum update -y
                amazon-linux-extras install docker -y
                service docker start
                usermod -a -G docker ec2-user
                chkconfig docker on
                yum install -y git
                docker pull sethsec/nodejs-ssrf-app
                docker run -d -p 12380:12380 sethsec/nodejs-ssrf-app 12380
                EOF

  tags = {
    Name = "wyatt"
  }
}


resource "aws_security_group" "wyatt" {
  name = "wyatt"
  description = "Cloudfox Security Group for ecs"
  vpc_id = "${var.vpc_id}"
  ingress {
      from_port = 12380
      to_port =  12380
      protocol = "tcp"
      cidr_blocks = [var.vpc_cidr]
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
    Name = "wyatt-http"
    Stack = "CloudFox"
  }
}

resource "aws_iam_role" "wyatt" {
  name                = "wyatt"
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

resource "aws_iam_instance_profile" "wyatt" {
  name = "wyatt"
  role = aws_iam_role.wyatt.name
}

// create a policy that can read from dynamodb
resource "aws_iam_policy" "wyatt" {
  name = "wyatt"
  policy = jsonencode({
    "Version" = "2012-10-17"
    "Statement" = [
      {
        "Effect" = "Allow"
        "Action" = [
          "dynamodb:GetItem",
          "dynamodb:BatchGetItem",
          "dynamodb:Query",
          "dynamodb:Scan",

        ]
        "Resource" = [
          "${aws_dynamodb_table.wyatt.arn}",
        ]
      }
    ]
  })
}

// attach the policy to the role

resource "aws_iam_role_policy_attachment" "wyatt" {
  role       = aws_iam_role.wyatt.name
  policy_arn = aws_iam_policy.wyatt.arn
}

resource "aws_iam_role_policy_attachment" "ssmcore" {
  role       = aws_iam_role.wyatt.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

}  



resource "aws_dynamodb_table" "wyatt" {
  name           = "wyatt-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "null_resource" "insert_records" {
  depends_on = [aws_dynamodb_table.wyatt]

  provisioner "local-exec" {
    command = <<-EOT
      aws --region "${var.AWS_REGION}" --profile "${var.aws_local_profile}" dynamodb put-item --table-name ${aws_dynamodb_table.wyatt.name} --item '{"id": {"S": "record1"}, "data": {"S": "Sample data 1"}}' && \
      aws --region "${var.AWS_REGION}" --profile "${var.aws_local_profile}" dynamodb put-item --table-name ${aws_dynamodb_table.wyatt.name} --item '{"id": {"S": "record2"}, "data": {"S": "Sample data 2"}, "ctf_flag": {"S": "FLAG{wyatt::So_Many_DBs_To_Look_Through}"}}' && \
      aws --region "${var.AWS_REGION}" --profile "${var.aws_local_profile}" dynamodb put-item --table-name ${aws_dynamodb_table.wyatt.name} --item '{"id": {"S": "record3"}, "data": {"S": "Sample data 3"}}'
    EOT
  }
}

