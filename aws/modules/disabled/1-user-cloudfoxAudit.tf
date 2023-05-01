# ####################
# # Create a cloudfox assessment role and attach the right policies
# ####################

# resource "aws_iam_policy" "CloudFox-policy-perms" {
#   name        = "CloudFox-policy-perms"
#   path        = "/"
#   description = "All CloudFox permissions"

#   # Terraform's "jsonencode" function converts a
#   # Terraform expression result to valid JSON syntax.
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#                 "apigateway:GET",                
#                 "apprunner:DescribeService",
#                 "apprunner:ListServices",                
#                 "cloudformation:ListStacks",
#                 "cloudtrail:LookupEvents",
#                 "cloudfront:ListDistributions",
#                 "ec2:DescribeInstanceAttribute",
#                 "ec2:DescribeInstances",
#                 "ec2:DescribeRegions",
#                 "ecr:DescribeImages",
#                 "ecr:DescribeRepositories",
#                 "ecs:DescribeTaskDefinition",
#                 "ecs:ListTaskDefinitions",
#                 "elasticfilesystem:DescribeFileSystemPolicy",
#                 "elasticfilesystem:DescribeFileSystems",
#                 "elasticfilesystem:DescribeMountTargets",
#                 "eks:DescribeCluster",
#                 "eks:ListClusters",
#                 "elasticloadbalancing:DescribeLoadBalancers",
#                 "elasticloadbalancing:DescribeListeners",                            
#                 "fsx:DescribeFileSystems",
#                 "fsx:DescribeVolumes",
#                 "grafana:ListWorkspaces",
#                 "iam:ListAccessKeys",
#                 "iam:ListUsers",
#                 "iam:ListRoles",
#                 "iam:SimulatePrincipalPolicy",
#                 "iam:GetAccountAuthorizationDetails",
#                 "lambda:GetFunctionUrlConfig",
#                 "lambda:ListFunctions",                
#                 "lightsail:GetContainerServices",
#                 "lightsail:GetInstances",
#                 "mq:DescribeBroker",
#                 "mq:ListBrokers",
#                 "es:DescribeDomain",
#                 "es:ListDomainNames",
#                 "rds:DescribeDBInstances",
#                 "redshift:DescribeClusters",
#                 "route53:ListHostedZones",
#                 "route53:ListResourceRecordSets",
#                 "s3:GetBucketPolicyStatus",
#                 "s3:GetBucketWebsite",
#                 "s3:ListAllMyBuckets",
#                 "ssm:DescribeParameters",
#                 "sagemaker:ListProcessingJobs",
#                 "sagemaker:DescribeProcessingJob",
#                 "sagemaker:ListTransformJobs",
#                 "sagemaker:DescribeTransformJob",
#                 "sagemaker:ListTrainingJobs",
#                 "sagemaker:DescribeTrainingJob",
#                 "sagemaker:ListModels",
#                 "sagemaker:DescribeModel",                
#                 "secretsmanager:ListSecrets"
#             ]
#         Effect   = "Allow"
#         Resource = "*"
#       },
#     ]
#   })
# }


# resource "aws_iam_user" "cloudfoxAudit" {
#   name = "cloudfoxAudit"
#   path = "/"
# }
# resource "aws_iam_access_key" "cloudfoxAudit" {
#   user = aws_iam_user.cloudfoxAudit.name
# }


# resource "aws_iam_user_policy_attachment" "cloudfox-policy1" {
#   user       = aws_iam_user.cloudfoxAudit.name
#   policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"

# }  

# resource "aws_iam_user_policy_attachment" "cloudfox-policy2" {
#   user       = aws_iam_user.cloudfoxAudit.name
#   policy_arn = aws_iam_policy.CloudFox.arn

# }  

# output "cloudfoxAudit_user_output_access_key_id" {
#   value     = aws_iam_access_key.cloudfoxAudit.id  
# }
# output "cloudfoxAudit_user_output_secret_access_key" {
#   value     = aws_iam_access_key.cloudfoxAudit.secret
#   sensitive = true  
# }

