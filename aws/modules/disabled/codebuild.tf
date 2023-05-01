resource "aws_codebuild_project" "ssrf-app" {
  name = "ssrf-app"
  service_role  = aws_iam_role.cf-codebuild-role.arn
  description   = "test_codebuild_project"
  build_timeout = "5"
  cache {
    type     = "S3"
    location = aws_s3_bucket.cf-codebuild-bucket.id
  }
  
  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/standard:6.0"
    type = "LINUX_CONTAINER"
    privileged_mode = true
  
  environment_variable {
      name  = "ECR_REPOSITORY"
      value = aws_ecr_repository.node-ssrf-app.repository_url
    }
  
  }

  source {
    type = "GITHUB"
    location = "https://github.com/sethsec/Nodejs-SSRF-App"
    buildspec = file("${path.module}/codebuild-buildspec.yml")
    git_clone_depth = 1
  }
}


resource "aws_s3_bucket" "cf-codebuild" {
  bucket = "cf-codebuild-${random_string.resource-suffix.result}"
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.cf-codebuild.id
  acl    = "private"
}


resource "aws_iam_role" "cf-codebuild-role" {
  name = "cf-codebuild-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ssrf-app-policy" {
  role = aws_iam_role.cf-codebuild-role.name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs"
      ],
      "Resource": "*"
    },
        {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:CompleteLayerUpload",
        "ecr:GetAuthorizationToken",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart"        
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterfacePermission"
      ],
      "Resource": [
        "arn:aws:ec2:us-east-1:123456789012:network-interface/*"
      ],
      "Condition": {
        "StringEquals": {
          "ec2:Subnet": [
            "${aws_subnet.cloudfox-operational-1.arn}",
            "${aws_subnet.cloudfox-operational-2.arn}"
          ],
          "ec2:AuthorizedService": "codebuild.amazonaws.com"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${aws_s3_bucket.cf-codebuild.arn}",
        "${aws_s3_bucket.cf-codebuild.arn}/*"
      ]
    }
  ]
}
POLICY
}


resource "null_resource" "start-build-create-ecr" {
  depends_on = [
    aws_codebuild_project.ssrf-app,
    aws_iam_role_policy.ssrf-app-policy,    
  ]

  provisioner "local-exec" {
    working_dir = path.module
    on_failure  = fail
    #interpreter = ["bash", "-c"]
       
    command     = <<EOF
        
        aws --region "${var.AWS_REGION}" --profile "${var.aws_local_profile}" codebuild start-build --project-name "${aws_codebuild_project.ssrf-app.name}";
    EOF
  }
}

resource "aws_s3_bucket" "cf-codebuild-bucket" {
  bucket = "cf-codebuild1-${random_string.resource-suffix.result}"
}