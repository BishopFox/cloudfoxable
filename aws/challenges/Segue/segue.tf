//create a policy that has security audit permissions as well as iam:assumeRole for deployment_automation and read/get permissions to deployment_automation S3 bucket
resource "aws_iam_policy" "authorized_deployers" {
  name        = "authorized_deployers"
  path        = "/"
  description = "policy for authorized deployers in the organization"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "sts:AssumeRole"
        ],
        "Resource" : [
          "arn:aws:iam::${var.account_id}:role/deployment_automation",
          "arn:aws:iam::992382614597:role/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        "Resource" : [
          aws_s3_bucket.deployment-automation.arn,
          "${aws_s3_bucket.deployment-automation.arn}/*"
        ]
      }
    ]
  })
}

// create iam role that trusts the ctf starting user
resource "aws_iam_role" "reinier" {
  name                = "reinier"
  assume_role_policy  = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          "AWS": ["arn:aws:iam::${var.account_id}:user/${var.ctf_starting_user_name}"]
        }
      },
    ]
  })
}

//attach the policy to the role
resource "aws_iam_role_policy_attachment" "authorized_deployers-attachment" {
  role       = aws_iam_role.reinier.name
  policy_arn = aws_iam_policy.authorized_deployers.arn
}

//also attach security audit, just to add some extra unnecessary permissions
resource "aws_iam_role_policy_attachment" "security_audit-attachment" {
  role       = aws_iam_role.reinier.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}  

//create segue-flag in secretsmanager
resource "aws_secretsmanager_secret" "SegueFlag" {
  name                    = "SegueFlag"
  recovery_window_in_days = 0
  tags = {
    Name = "Segue flag"
  }
}

resource "aws_secretsmanager_secret_version" "SegueFlag" {
  secret_id     = aws_secretsmanager_secret.SegueFlag.id
  secret_string = "Thank you, but your flag is in another castle"
}

//create a policy for deployment_automation that has permissions to assume the secret_reader role
resource "aws_iam_policy" "deployment_automation" {
  name        = "deployment_automation"
  path        = "/"
  description = "policy for automated deployment"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "sts:AssumeRole"
        ],
        "Resource" : "arn:aws:iam::${var.account_id}:role/secret_reader"
      }
    ]
  })
}

// create deployment_automation role
resource "aws_iam_role" "deployment_automation" {
  name                = "deployment_automation"
  assume_role_policy  = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          "AWS": ["arn:aws:iam::${var.account_id}:role/reinier"]
        }
      },
    ]
  })
}

//attach the deployment_automation policy to the deployment_automation role
resource "aws_iam_role_policy_attachment" "deployment_automation-attachment" {
  role       = aws_iam_role.deployment_automation.name
  policy_arn = aws_iam_policy.deployment_automation.arn
}

//create a policy that has permissions to read flag from secretsmanager
resource "aws_iam_policy" "secret_reader" {
  name        = "secret_reader"
  path        = "/"
  description = "policy for reading secrets"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:ListSecrets"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:GetSecretValue"
        ],
        "Resource" : aws_secretsmanager_secret.SegueFlag.arn
      }
    ]
  })
}

// create role to read secrets
resource "aws_iam_role" "secret_reader" {
  name                = "secret_reader"
  assume_role_policy  = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          "AWS": ["arn:aws:iam::${var.account_id}:role/deployment_automation"]
        }
      },
    ]
  })
}

//attach the secret_reader policy to the secret_reader role
resource "aws_iam_role_policy_attachment" "secret_reader-attachment" {
  role       = aws_iam_role.secret_reader.name
  policy_arn = aws_iam_policy.secret_reader.arn
}

//create S3 bucket
resource "aws_s3_bucket" "deployment-automation" {
  bucket = "deployment-automation-${random_string.resource-suffix.result}"
  force_destroy = true
  tags = {
    Name        = "deployment-automation-${random_string.resource-suffix.result}"
  }
}

# resource "aws_s3_bucket_acl" "cdeployment-automation-acl" {
#   bucket = aws_s3_bucket.cdeployment-automation.id
#   acl    = "private"
# }

resource "aws_s3_bucket_public_access_block" "deployment-automation-public-access-block" {
  bucket = aws_s3_bucket.deployment-automation.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

// upload a file to the bucket.
resource "aws_s3_object" "deployment-automation-object" {
  bucket = aws_s3_bucket.deployment-automation.id
  key    = "Security Review Process.pdf"
  source = "challenges/Segue/data/s3/Security Review Process.pdf"
}

// upload another file to the bucket.
resource "aws_s3_object" "deployment-automation-object-2" {
  bucket = aws_s3_bucket.deployment-automation.id
  key    = "Deployment Process Description.pdf"
  source = "challenges/Segue/data/s3/Deployment Process Description.pdf"
}