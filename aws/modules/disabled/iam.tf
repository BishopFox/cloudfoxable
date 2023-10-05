####################
# Create a couple of admin policies and roles, and attach them together
####################
resource "aws_iam_policy" "service-admin" {
  name        = "service-admin"
  path        = "/"
  description = ""

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "*"
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_policy" "cf-admin" {
  name        = "cf-admin"
  path        = "/"
  description = "All CloudFormation actions"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "cloudformation:*"
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_policy" "lambda-admin" {
  name        = "lambda-admin"
  path        = "/"
  description = "All lambda actions"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "lambda:*"
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_policy" "ec2-admin" {
  name        = "ec2-admin"
  path        = "/"
  description = "All ec2 actions"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "ec2:*"
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}



data "aws_iam_policy" "AmazonSSMManagedInstanceCore" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role" "ec2-admin-role" {
  name                = "press"
  assume_role_policy  = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = [
            "ec2.amazonaws.com"
          ]            
        }
      },
    ]
  })
}

resource "aws_iam_instance_profile" "service-admin_profile" {
 name = "service-admin-profile"
 role = aws_iam_role.ec2-admin-role.name
}

resource "aws_iam_role_policy_attachment" "ec2-admin-role-attach-policy1" {
  role       = aws_iam_role.ec2-admin-role.name
  policy_arn = aws_iam_policy.service-admin.arn

}  
resource "aws_iam_role_policy_attachment" "ec2-admin-role-attach-policy2" {
  role       = aws_iam_role.ec2-admin-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

}  


resource "aws_iam_role" "cf-admin-role" {
  name                = "lloyd"
  assume_role_policy  = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = [
            "cloudformation.amazonaws.com"
          ]            
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cf-admin-role-attach-policy1" {
  role       = aws_iam_role.cf-admin-role.name
  policy_arn = aws_iam_policy.cf-admin.arn

}  

resource "aws_iam_role" "lambda-admin-role" {
  name                = "lavelle"
  assume_role_policy  = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = [
            "lambda.amazonaws.com"
          ]            
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda-admin-role-attach-policy1" {
  role       = aws_iam_role.lambda-admin-role.name
  policy_arn = aws_iam_policy.lambda-admin.arn

}  

####################
# Create a cloudfox assessment role and attach the right policies
####################

resource "aws_iam_policy" "CloudFox" {
  name        = "CloudFox"
  path        = "/"
  description = "All CloudFox permissions"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
                "apigateway:GET",                
                "apprunner:DescribeService",
                "apprunner:ListServices",                
                "cloudformation:ListStacks",
                "cloudtrail:LookupEvents",
                "cloudfront:ListDistributions",
                "ec2:DescribeInstanceAttribute",
                "ec2:DescribeInstances",
                "ec2:DescribeRegions",
                "ecr:DescribeImages",
                "ecr:DescribeRepositories",
                "ecs:DescribeTaskDefinition",
                "ecs:ListTaskDefinitions",
                "elasticfilesystem:DescribeFileSystemPolicy",
                "elasticfilesystem:DescribeFileSystems",
                "elasticfilesystem:DescribeMountTargets",
                "eks:DescribeCluster",
                "eks:ListClusters",
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:DescribeListeners",                            
                "fsx:DescribeFileSystems",
                "fsx:DescribeVolumes",
                "grafana:ListWorkspaces",
                "iam:ListAccessKeys",
                "iam:ListUsers",
                "iam:ListRoles",
                "iam:SimulatePrincipalPolicy",
                "iam:GetAccountAuthorizationDetails",
                "lambda:GetFunctionUrlConfig",
                "lambda:ListFunctions",                
                "lightsail:GetContainerServices",
                "lightsail:GetInstances",
                "mq:DescribeBroker",
                "mq:ListBrokers",
                "es:DescribeDomain",
                "es:ListDomainNames",
                "rds:DescribeDBInstances",
                "redshift:DescribeClusters",
                "route53:ListHostedZones",
                "route53:ListResourceRecordSets",
                "s3:GetBucketPolicyStatus",
                "s3:GetBucketWebsite",
                "s3:ListAllMyBuckets",
                "ssm:DescribeParameters",
                "sagemaker:ListProcessingJobs",
                "sagemaker:DescribeProcessingJob",
                "sagemaker:ListTransformJobs",
                "sagemaker:DescribeTransformJob",
                "sagemaker:ListTrainingJobs",
                "sagemaker:DescribeTrainingJob",
                "sagemaker:ListModels",
                "sagemaker:DescribeModel",                
                "secretsmanager:ListSecrets"
            ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "CloudFox-exec-role" {
  name                = "CloudFox-exec-role"
  assume_role_policy  = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          AWS = [
            "arn:aws:iam::${var.account_id}:user/security",
          ]            
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "CloudFox-role-attach-policy1" {
  role       = aws_iam_role.CloudFox-exec-role.name
  policy_arn = aws_iam_policy.CloudFox.arn

}  

resource "aws_iam_role_policy_attachment" "CloudFox-role-attach-policy2" {
  role       = aws_iam_role.CloudFox-exec-role.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"

}  

resource "aws_iam_user" "security" {
  name = "security"
  path = "/"
}
resource "aws_iam_access_key" "security" {
  user = aws_iam_user.security.name
}



####################
# Assume Role chain challenge 
####################


resource "aws_iam_policy" "assume-roles-policy" {
  name        = "assume-roles"
  path        = "/"
  description = "Can sts:AssumeRole"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action = "sts:AssumeRole"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "assume-roles-attachment" {
  role       = aws_iam_role.ec2InstanceConnect.name
  policy_arn = aws_iam_policy.assume-roles-policy.arn

}  



resource "aws_iam_policy" "not-admin-access" {
  name        = "not-admin-access"
  path        = "/"
  description = "Allows privesc via targeted sts:AssumeRole"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action = "*"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "not-admin" {
  name                = "not-admin"
  assume_role_policy  = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          AWS = aws_iam_user.pele.arn
        }
      },
    ]
  })
}



resource "aws_iam_user" "pele" {
  name = "pele"
  path = "/"
}
resource "aws_iam_access_key" "pele" {
  user = aws_iam_user.pele.name
}
resource "aws_iam_role_policy_attachment" "not-admin-access-role-attach-policy" {
  role       = aws_iam_role.not-admin.name
  policy_arn = aws_iam_policy.not-admin-access.arn

}  



