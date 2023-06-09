resource "aws_secretsmanager_secret" "database-secret" {
  name                    = "database-secret"
  recovery_window_in_days = 0
  tags = {
    Name = "Database Secret"
  }

}

resource "aws_secretsmanager_secret_version" "database-secret" {
  secret_id     = aws_secretsmanager_secret.database-secret.id
  secret_string = random_password.database-secret.result
}

resource "aws_secretsmanager_secret" "corporate-domain-admin-password" {
  name                    = "DomainAdministratorCredentials"
  
  recovery_window_in_days = 0
  tags = {
    Name = "Corporate Domain Admin Password"
  }

}

resource "aws_secretsmanager_secret_version" "corporate-domain-admin-password" {
  secret_id     = aws_secretsmanager_secret.corporate-domain-admin-password.id
  secret_string = "FLAG{backwards::IfYouFindSomethingInterstingFindWhoHasAccessToIt}"
}

//create a policy that only has access to the corporate-domain-admin-password secret
resource "aws_iam_policy" "corporate-domain-admin-password-policy" {
  name        = "corporate-domain-admin-password-policy"
  path        = "/"
  description = "policy that only allows access to the corporate-domain-admin-password secret"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:GetSecretValue"
        ],
        "Resource" : [
          aws_secretsmanager_secret.corporate-domain-admin-password.arn
        ]
      }
    ]
  })
}

//create iam role that trusts the ctf starting user and attach the policy to it
resource "aws_iam_role" "Alexander-Arnold" {
  name               = "Alexander-Arnold"
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

//attach the policy to the role
resource "aws_iam_role_policy_attachment" "corporate-domain-admin-password-policy-attachment" {
  role       = aws_iam_role.Alexander-Arnold.name
  policy_arn = aws_iam_policy.corporate-domain-admin-password-policy.arn
}