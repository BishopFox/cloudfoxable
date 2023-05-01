resource "aws_ssm_parameter" "secret1" {
  name  = "/production/database/username"
  type  = "String"
  value = "admin"
}

resource "aws_ssm_parameter" "secret2" {
  name  = "/production/database/password"
  type  = "SecureString"
  value = "USMNT2023"
}


resource "aws_ssm_parameter" "secret3" {
  name  = "/staging/database/user"
  type  = "String"
  value = "admin"
}


resource "aws_ssm_parameter" "secret4" {
  name  = "/staging/database/password"
  type  = "String"
  value = "USMNT2023"
}

resource "aws_ssm_parameter" "flag" {
    name  = "/cloudfoxable/flag/its-a-secret"
    type  = "SecureString"
    value = "{FLAG:IsASecretASecretIfTooManyPeopleHaveAccessToIt?}"
}

// create an iam policy that only allows access to this flag
resource "aws_iam_policy" "its-a-secret-policy" {
  name        = "its-a-secret-policy"
  path        = "/"
  description = "policy that only allows access to the its-a-secret flag"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameter"
        ],
        "Resource" : [
          aws_ssm_parameter.flag.arn
        ]
      }
    ]
  })
}

// attach this policy to the CTF starting user
resource "aws_iam_user_policy_attachment" "its-a-secret-policy-attachment" {
  user       = var.ctf_starting_user_name
  policy_arn = aws_iam_policy.its-a-secret-policy.arn
}

