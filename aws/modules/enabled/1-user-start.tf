resource "aws_iam_policy" "startUser" {
  name        = "startUser"
  path        = "/"
  description = "All startUser permissions"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # {
      #   Action = [
      #           "sns:Subscribe",
      #           "sns:ListSubscriptionsByTopic",
      #           "sns:ListTopics",
      #           "sns:Receive",
      #           "sqs:SendMessage",
      #           "sqs:ReceiveMessage",
      #           "sqs:DeleteMessage",
      #           "sqs:GetQueueAttributes",
      #           "sqs:ListQueues",
      #       ]
      #   Effect   = "Allow"
      #   Resource = "*"
      # },
      {
        Effect = "Allow"
        Action = "secretsmanager:ListSecrets"
        Resource = "${aws_secretsmanager_secret.app-secret.arn}"

      },
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = [ 
                "arn:aws:iam::${var.account_id}:role/mkennie",
                "arn:aws:iam::${var.account_id}:role/abcd"
        ]
      }
    ]
  })
}




####################
# Create a cloudfox assessment role and attach the right policies
####################

resource "aws_iam_policy" "CloudFox-policy-perms" {
  name        = "CloudFox-policy-perms"
  path        = "/"
  description = "All CloudFox permissions"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Action": [
                "apigateway:GET",                
                "apprunner:DescribeService",
                "apprunner:ListServices",
                "cloudformation:DescribeStacks",
                "cloudformation:GetTemplate",
                "cloudformation:ListStacks",
                "cloudtrail:LookupEvents",
                "cloudfront:ListDistributions",
                "dynamodb:ListTables",
                "ec2:DescribeInstanceAttribute",
                "ec2:DescribeInstances",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeRegions",
                "ecr:DescribeImages",
                "ecr:DescribeRepositories",
                "ecs:DescribeTaskDefinition",
                "ecs:ListClusters",                
                "ecs:ListTaskDefinitions",
                "ecs:ListTasks",
                "eks:DescribeCluster",
                "eks:DescribeNodegroup",
                "eks:ListClusters",
                "eks:ListNodegroups",
                "elasticache:DescribeCacheClusters",
                "elasticache:DescribeCacheSubnetGroups",
                "elasticache:DescribeReplicationGroups",
                "elasticfilesystem:DescribeFileSystemPolicy",
                "elasticfilesystem:DescribeFileSystems",
                "elasticfilesystem:DescribeMountTargets",
                "eks:DescribeCluster",
                "eks:ListClusters",
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:DescribeListeners",                            
                "fsx:DescribeFileSystems",
                "fsx:DescribeVolumes",
                "glue:ListDevEndpoints",
                "glue:ListJobs",
                "grafana:ListWorkspaces",
                "iam:GetAccountAuthorizationDetails",
                "iam:ListAccessKeys",
                "iam:ListUsers",
                "iam:ListRoles",
                "iam:SimulatePrincipalPolicy",
                "lambda:GetFunctionUrlConfig",
                "lambda:ListFunctions",                
                "lightsail:GetContainerServices",
                "lightsail:GetInstances",
                "mq:DescribeBroker",
                "mq:ListBrokers",
                "es:DescribeDomain",
                "es:ListDomainNames",
                "ram:GetResourceShares",
                "ram:ListResources",
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
                "secretsmanager:ListSecrets",
                "sns:ListTopics",
                "sqs:ListQueues",
                "tag:GetResources"
            ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}


resource "aws_iam_user" "ctf-starting-user" {
  name = "ctf-starting-user"
  path = "/"
}
resource "aws_iam_access_key" "ctf-starting-user" {
  user = aws_iam_user.ctf-starting-user.name
}


resource "aws_iam_user_policy_attachment" "ctf-policy1" {
  user       = aws_iam_user.ctf-starting-user.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"

}  

// Attach the CloudFox policy to the user
resource "aws_iam_user_policy_attachment" "ctf-policy2" {
  user       = aws_iam_user.ctf-starting-user.name
  policy_arn = aws_iam_policy.CloudFox-policy-perms.arn
}

// Attach the startUser policy to the user
resource "aws_iam_user_policy_attachment" "ctf-policy3" {
  user       = aws_iam_user.ctf-starting-user.name
  policy_arn = aws_iam_policy.startUser.arn
}


output "ctf_user_output_access_key_id" {
  value     = aws_iam_access_key.ctf-starting-user.id  
}
output "ctf_user_output_secret_access_key" {
  value     = aws_iam_access_key.ctf-starting-user.secret  
}

output "ctf_starting_user_arn" {
  value       = aws_iam_user.ctf-starting-user.arn
  description = "ARN of the CTF starting user"
}

output "ctf_starting_user_name" {
  value       = aws_iam_user.ctf-starting-user.name
  description = "Name of the CTF starting user"
}