resource "aws_ssm_parameter" "flag2" {
    name  = "/cloudfoxable/flag/its-another-secret"
    type  = "SecureString"
    value = "FLAG{ItsAnotherSecret::ThereWillBeALotOfAssumingRolesInThisCTF}"
}

// create an iam policy that only allows access to this flag
resource "aws_iam_policy" "its-another-secret-policy" {
  name        = "its-another-secret-policy"
  path        = "/"
  description = "policy that only allows access to the its-another-secret flag"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameter"
        ],
        "Resource" : [
          aws_ssm_parameter.flag2.arn
        ]
      }
    ]
  })
}

// create iam role that trusts the ctf starting user and attach the policy to it
resource "aws_iam_role" "its-another-secret-role" {
  name               = "Ertz"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${var.account_id}:user/${var.ctf_starting_user_name}"
          ]
        },
        "Action" : [
          "sts:AssumeRole"
        ]
      }
    ]
  })
}

// attach the policy to the role
resource "aws_iam_role_policy_attachment" "its-a-secret-policy-attachment" {
  role       = aws_iam_role.its-another-secret-role.name
  policy_arn = aws_iam_policy.its-another-secret-policy.arn
}


