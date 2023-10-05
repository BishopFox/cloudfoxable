
# resource "aws_iam_role" "cloud9_role" {
#   name               = "Cloud9InstanceRole"
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "ec2.amazonaws.com"
#       },
#       "Effect": "Allow",
#       "Sid": ""
#     }
#   ]
# }
# EOF
# }

# resource "aws_iam_role_policy_attachment" "cloud9_policy_attachment" {
#   policy_arn = "arn:aws:iam::aws:policy/AWSCodeCommitReadOnly" # This is just an example, adjust the permissions accordingly.
#   role       = aws_iam_role.cloud9_role.name
# }

# resource "aws_cloud9_environment_ec2" "example" {
#   instance_type     = "t2.micro" # or any other desired instance type
#   subnet_id         = var.subnet1_id 
#   name              = "my-cloud9-env"
#   owner_arn         = aws_iam_role.cloud9_role.arn
#   automatic_stop_time_minutes = 30 # Automatically stop the environment after it's inactive for 30 minutes
# }


# resource "aws_iam_role" "test_cloud9_role" {
#   name               = "test_cloud9"
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal" : {
#           "AWS" : [
#               "arn:aws:iam::${var.account_id}:user/${var.ctf_starting_user_name}"
#           ]
#       },
#       "Effect": "Allow",
#       "Sid": ""
#     }
#   ]
# }
# EOF
# }


# resource "aws_iam_policy" "cloud9_access_for_test_policy" {
#   name        = "Cloud9AccessForTestPolicy"
#   description = "Allows test_cloud9 role to access Cloud9"

#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": "cloud9:DescribeEnvironments",
#       "Resource": "*"
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#         "cloud9:CreateEnvironmentMembership",
#         "cloud9:DeleteEnvironmentMembership",
#         "cloud9:DescribeEnvironmentMemberships",
#         "cloud9:DescribeEnvironmentStatus",
#         "cloud9:UpdateEnvironment"
#       ],
#       "Resource": ${aws_cloud9_environment_ec2.example.id}
#     }
#   ]
# }
# EOF
# }

# resource "aws_iam_role_policy_attachment" "test_cloud9_cloud9_attachment" {
#   policy_arn = aws_iam_policy.cloud9_access_for_test_policy.arn
#   role       = aws_iam_role.test_cloud9_role.name
# }



