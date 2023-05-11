// iam role that trusts a github repo to assume it as part of an OIDC flow
resource "aws_iam_role" "blurred-lines-1" {
  name = "t_rodman"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Principal": {
        "Federated": "arn:aws:iam::${var.account_id}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Condition": {
        "StringLike": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
                    "token.actions.githubusercontent.com:sub": "repo:${var.github_repo}:*"
                }
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


// create an identity provider for the github OIDC flow
resource "aws_iam_openid_connect_provider" "github" {
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
  url = "https://token.actions.githubusercontent.com"
}

// create a ssm parameter to store the flag for this challenge 
resource "aws_ssm_parameter" "blurred-lines-1-flag" {
  name = "/cloudfox/blurred-lines-1/flag"
  type = "SecureString"
  value = "FLAG{the_lines_have_been_blurred}"
  overwrite = true
}

// create a policy to allow the github OIDC role to read the flag
resource "aws_iam_policy" "blurred-lines-1" {
  name = "blurred-lines-1"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowReadFlag",
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter"
      ],
      "Resource": [
        "${aws_ssm_parameter.blurred-lines-1-flag.arn}"
      ]
    }   
  ]
}
EOF
}

// attach the policy to the github OIDC role
resource "aws_iam_role_policy_attachment" "blurred-lines-1" {
  role = aws_iam_role.blurred-lines-1.name
  policy_arn = aws_iam_policy.blurred-lines-1.arn
}