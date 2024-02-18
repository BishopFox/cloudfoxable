resource "aws_iam_role" "root-role" {
  name               = "Kent"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            "${var.ctf_starting_user_arn}"
          ]
        },
        "Action" : [
          "sts:AssumeRole"
        ]
      }
    ]
  })
}




resource "aws_iam_policy" "root-policy1" {
  name        = "root-policy1"
  path        = "/"
  description = ""

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [      
      "sts:AssumeRole",
    ],
        Effect   = "Allow"
        Resource = "*"
      },      
    ]
  })
}

// attach root-policy1 to root-role
resource "aws_iam_role_policy_attachment" "root-policy1-role-attach-policy" {
  role       = aws_iam_role.root-role.name
  policy_arn = aws_iam_policy.root-policy1.arn
}

resource "aws_iam_role" "privesc-AssumeRole-intermediate-role" {
  name                = "Beard"
  assume_role_policy  = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          AWS = var.aws_root_user
        }
      },
    ]
  })
}


resource "aws_iam_role" "privesc-AssumeRole-ending-role" {
  name                = "Lasso"
  assume_role_policy  = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          AWS = aws_iam_role.privesc-AssumeRole-intermediate-role.arn
        }
      },
    ]
  })
}


resource "aws_iam_policy" "privesc-AssumeRole-high-priv-policy" {
  name        = "important-policy"
  path        = "/"
  description = ""

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action = "ssm:GetParameter"
        Resource = aws_ssm_parameter.secret1.arn
      },
    ]
  })
}


resource "aws_iam_role_policy_attachment" "privesc-AssumeRole-high-priv-policy-role-attach-policy" {
  role       = aws_iam_role.privesc-AssumeRole-ending-role.name
  policy_arn = aws_iam_policy.privesc-AssumeRole-high-priv-policy.arn

}  


resource "aws_ssm_parameter" "secret1" {
  name  = "/production/CICD/root"
  type  = "SecureString"
  value = "FLAG{root::ExploitingRoleTrustsIsFun}"
}