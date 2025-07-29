// create users
locals {
  users = ["terraform", "webgitactions", "dbgitactions", "white-rabbit", "dbuseracct"]
  repos = ["webapp", "database", "test"]
}

resource "aws_iam_user" "user" {
  for_each = toset(local.users)
  name     = each.key
}

resource "aws_iam_access_key" "access_key" {
  for_each = aws_iam_user.user
  user     = each.value.name
}

# Create the DB secret
resource "aws_secretsmanager_secret" "db_credentials" {
  name = "database_credentials"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = "admin"
    password = "supersecret"
  })
}

///////////////////////////////////////////////////////////////////////////////////////////////
# Create an ECR repository
resource "aws_ecr_repository" "repo" {
  for_each = toset(local.repos)
  name     = each.key
}

locals {
  ecr_repository_arns = [
    for repo in aws_ecr_repository.repo :
    repo.arn
  ]
}


# Temporary disable for testing
#
resource "null_resource" "build" {
  # Runs the build.sh script which builds the dockerfile and pushes to ecr
  triggers = {
    access_key_id  = aws_iam_access_key.access_key["terraform"].id
    secret_access_key = aws_iam_access_key.access_key["terraform"].secret
  }
 
  provisioner "local-exec" {
    environment = {
      ACCESS_KEY_ID     = aws_iam_access_key.access_key["terraform"].id
      SECRET_ACCESS_KEY = aws_iam_access_key.access_key["terraform"].secret
    }

    command = <<-EOT
    cp -f ${path.module}/data/templates/webapp/app.py ${path.module}/data/docker/webapp/app.py
    cp -f ${path.module}/data/templates/webapp/entrypoint.sh ${path.module}/data/docker/webapp/entrypoint.sh
    cp -f ${path.module}/data/templates/webapp/requirements.txt ${path.module}/data/docker/webapp/requirements.txt
    cp -f ${path.module}/data/templates/webapp/web.dockerfile ${path.module}/data/docker/webapp/Dockerfile
    for i in $(seq 1 5); do sed -i "s/^ENV VERSION=.*$/ENV VERSION=$i/g" ${path.module}/data/docker/webapp/Dockerfile; bash ${path.module}/data/bin/build.sh ${path.module}/data/docker/webapp ${aws_ecr_repository.repo["webapp"].repository_url}:v$i ${var.AWS_REGION}; done
    
    max_attempts=5
    attempt_num=1
    success=false

    while [ "$success" = false ] && [ "$attempt_num" -le "$max_attempts" ]; do
      # Replace with your command
      cp -f ${path.module}/data/templates/webapp/web2.dockerfile ${path.module}/data/docker/webapp/Dockerfile && \
        sed -i "s/^ENV AWS_ACCESS_KEY_ID=.*$/ENV AWS_ACCESS_KEY_ID=$ACCESS_KEY_ID/g" ${path.module}/data/docker/webapp/Dockerfile && \
        sed -i "s/^ENV AWS_SECRET_ACCESS_KEY=.*$/ENV AWS_SECRET_ACCESS_KEY=$SECRET_ACCESS_KEY/g" ${path.module}/data/docker/webapp/Dockerfile && \
        sed -i "s/^ENV VERSION=.*$/ENV VERSION=6/g" ${path.module}/data/docker/webapp/Dockerfile && \
        cp -f ${path.module}/data/docker/webapp/Dockerfile ${path.module}/data/docker/webapp/backup && \
        bash ${path.module}/data/bin/build.sh ${path.module}/data/docker/webapp ${aws_ecr_repository.repo["webapp"].repository_url}:v6 ${var.AWS_REGION}
      if [ "$?" -eq 0 ]; then
        success=true
      else
        echo "Attempt $attempt_num failed. Trying again..."
        attempt_num=$((attempt_num + 1))
      fi
    done

    if [ "$success" = true ]; then
      echo "Vulnerability added successfully after $attempt_num attempts."
    else
      echo "Vulnerability was not added successfully after $max_attempts attempts."
    fi
    
    rm -rf ${path.module}/data/docker/webapp/backup
    cp -f ${path.module}/data/templates/webapp/web.dockerfile ${path.module}/data/docker/webapp/Dockerfile
    for i in $(seq 7 15); do sed -i "s/^ENV VERSION=.*$/ENV VERSION=$i/g" ${path.module}/data/docker/webapp/Dockerfile; bash ${path.module}/data/bin/build.sh ${path.module}/data/docker/webapp ${aws_ecr_repository.repo["webapp"].repository_url}:v$i ${var.AWS_REGION}; done
    sed -i "s/^ENV VERSION=.*$/ENV VERSION=latest/g" ${path.module}/data/docker/webapp/Dockerfile
    bash ${path.module}/data/bin/build.sh ${path.module}/data/docker/webapp ${aws_ecr_repository.repo["webapp"].repository_url}:latest ${var.AWS_REGION}

    cp -f ${path.module}/data/templates/database/database.dockerfile ${path.module}/data/docker/database/Dockerfile
    cp -f ${path.module}/data/templates/database/get_secrets.sh ${path.module}/data/docker/database/get_secrets.sh
    cp -f ${path.module}/data/templates/database/entrypoint.sh ${path.module}/data/docker/database/entrypoint.sh
    sed -i "s/CHANGESECRETID/${aws_secretsmanager_secret.db_credentials.id}/g" ${path.module}/data/docker/database/get_secrets.sh
    sed -i "s/CHANGEREGION/${var.AWS_REGION}/g" ${path.module}/data/docker/database/Dockerfile
    sed -i "s/REPLACEACCESS/$ACCESS_KEY_ID/g" ${path.module}/data/docker/database/Dockerfile
    for i in $(seq 1 10); do sed -i "s/^ENV VERSION=.*$/ENV VERSION=$i/g" ${path.module}/data/docker/database/Dockerfile; bash ${path.module}/data/bin/build.sh ${path.module}/data/docker/database ${aws_ecr_repository.repo["database"].repository_url}:v$i ${var.AWS_REGION}; done
    sed -i "s/^ENV VERSION=.*$/ENV VERSION=latest/g" ${path.module}/data/docker/database/Dockerfile
    bash ${path.module}/data/bin/build.sh ${path.module}/data/docker/database ${aws_ecr_repository.repo["database"].repository_url}:latest ${var.AWS_REGION}

    cp -f ${path.module}/data/templates/test/dockerfile ${path.module}/data/docker/test/Dockerfile
    cp -f ${path.module}/data/templates/test/testfile ${path.module}/data/docker/test/testfile
    cp -f ${path.module}/data/templates/test/hello.py ${path.module}/data/docker/test/hello.py
    bash ${path.module}/data/bin/build.sh ${path.module}/data/docker/test ${aws_ecr_repository.repo["test"].repository_url}:latest ${var.AWS_REGION}

    EOT

  }
  depends_on = [aws_iam_access_key.access_key]
}

///////////////////////////////////////////////////////////////////////////////////////////////


// create iam role that trusts the ctf starting user
resource "aws_iam_role" "alice" {
  name                = "alice"
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

//alice permissions 
resource "aws_iam_policy" "authorized_devs" {
  name        = "authorized_devs"
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
          "arn:aws:iam::${var.account_id}:role/cheshire_cat",
          "arn:aws:iam::${var.account_id}:role/caterpillar",
          "arn:aws:iam::${var.account_id}:role/queen_of_hearts",
          "arn:aws:iam::${var.account_id}:role/mad_hatter"
        ]
      }
    ]
  })
}

//attach the policy to the role
resource "aws_iam_role_policy_attachment" "authorized_devs-attachment" {
  role       = aws_iam_role.alice.name
  policy_arn = aws_iam_policy.authorized_devs.arn
}

//also attach security audit, just to add some extra unnecessary permissions
resource "aws_iam_role_policy_attachment" "security_audit-attachment" {
  role       = aws_iam_role.alice.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}  
///////////////////////////////////////////////////////////////////////////////////////////////

// create iam mad_hatter role
resource "aws_iam_role" "mad_hatter" {
  name                = "mad_hatter"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      for arn in [
        "arn:aws:iam::${var.account_id}:role/alice",
        "arn:aws:iam::${var.account_id}:role/cheshire_cat",
        "arn:aws:iam::${var.account_id}:role/caterpillar",
        "arn:aws:iam::${var.account_id}:role/queen_of_hearts"
      ] : {
        Effect = "Allow",
        Principal = {
          AWS = arn
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

//attach read only access
resource "aws_iam_role_policy_attachment" "read-only-attachment" {
  role       = aws_iam_role.mad_hatter.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}  
///////////////////////////////////////////////////////////////////////////////////////////////

// create cheshire_cat role
resource "aws_iam_role" "cheshire_cat" {
  name = "cheshire_cat"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "*"
        },
        Action = "sts:AssumeRole",
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = "o-12345abcde"
          },
          StringLike = {
          "aws:PrincipalArn" = [
            "arn:aws:iam::${var.account_id}:role/alice",
            "arn:aws:iam::${var.account_id}:role/caterpillar",
            "arn:aws:iam::${var.account_id}:role/queen_of_hearts"
          ]
        }
        }
      },
      {
        Effect = "Allow",
        Principal = {
          AWS = [
            "arn:aws:iam::${var.account_id}:user/terraform",
            "arn:aws:iam::${var.account_id}:user/webgitactions",
            "arn:aws:iam::${var.account_id}:user/dbgitactions"
          ]
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}


// create terraform role
resource "aws_iam_role" "terraform" {
  name = "terraform"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = [
            "arn:aws:iam::${var.account_id}:user/terraform",
            "arn:aws:iam::${var.account_id}:user/webgitactions",
            "arn:aws:iam::${var.account_id}:user/dbgitactions"
          ]
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}


//attach the cheshire_cat policy to the cheshire_cat role
resource "aws_iam_role_policy_attachment" "cheshire_cat-attachment" {
  role       = aws_iam_role.cheshire_cat.name
  policy_arn = aws_iam_policy.cheshire_cat.arn
}

///////////////////////////////////////////////////////////////////////////////////////////////

// create queen_of_hearts role
resource "aws_iam_role" "queen_of_hearts" {
  name = "queen_of_hearts"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      for arn in [
        "arn:aws:iam::${var.account_id}:role/alice",
        "arn:aws:iam::${var.account_id}:role/cheshire_cat"
      ] : {
        Effect = "Allow",
        Principal = {
          AWS = arn
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

//attach the queen_of_hearts policy to the queen_of_hearts role
#resource "aws_iam_role_policy_attachment" "queen_of_hearts-attachment" {
#  role       = aws_iam_role.queen_of_hearts.name
#  policy_arn = aws_iam_policy.queen_of_hearts.arn
#}

///////////////////////////////////////////////////////////////////////////////////////////////

//create white rabbit flag2 in secretsmanager
resource "aws_secretsmanager_secret" "white-rabbit_flag2" {
  name                    = "white-rabbit_flag2"
  recovery_window_in_days = 0
  tags = {
    Name = "white rabbit flag2"
  }

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "WhiteRabbitFlag2",
        Effect   = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:role/cheshire_cat"
        },
        Action   = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = "*"
      },
      {
        Sid    = "DenyEveryoneElse",
        Effect = "Deny",
        Principal = "*",
        Action   = "*",
        Resource = "*",
        Condition = {
          StringNotLikeIfExists = {
            "aws:PrincipalArn" = [
              "arn:aws:iam::${var.account_id}:role/cheshire_cat",
              "arn:aws:iam::${var.account_id}:role/aws-reserved/sso.amazonaws.com/*/AWSReservedSSO_",
              "arn:aws:sts::${var.account_id}:assumed-role/AWSReservedSSO_*",
              "arn:aws:iam::${var.account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_*",
              "${var.aws_assume_role_arn}"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_secretsmanager_secret_version" "white-rabbit_flag2" {
  secret_id     = aws_secretsmanager_secret.white-rabbit_flag2.id
  secret_string = <<EOF
If you don't know where you want to go, any road will take you there. Then it doesn't matter which way you go.

FLAG2{RemoveAllCredentialsFromOldRepositories}
EOF
}

# Attach a resource policy to deny access to user and role named "terraform"
resource "aws_secretsmanager_secret_policy" "deny_terraform_access" {
  secret_arn = aws_secretsmanager_secret.white-rabbit_flag2.arn

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "DenyTerraformUserAccess",
        Effect = "Deny",
        Principal = {
          AWS = [
            "arn:aws:iam::${var.account_id}:user/terraform",
            "arn:aws:iam::${var.account_id}:role/terraform"
          ]
        },
        Action = "secretsmanager:*",
        Resource = "*"
      }
    ]
  })
}

//create a policy for cheshire_cat that has permissions to assume the secret_access role
resource "aws_iam_policy" "cheshire_cat" {
  name        = "cheshire_cat"
  path        = "/"
  description = "policy for cheshire_cat"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
          "Effect": "Allow",
          "Action": [
              "s3-outposts:Get*",
              "s3-outposts:List*"
          ],
          "Resource": "*"
      },
      {
          "Effect": "Allow",
          "Action": [
              "s3:Get*",
              "s3:List*",
              "s3:Describe*",
              "s3-object-lambda:Get*",
              "s3-object-lambda:List*"
          ],
          "Resource": "*"
      },
      {
          "Effect": "Allow",
          "Action": [
              "datasync:ListTasks",
              "datasync:ListLocations",
              "datasync:DescribeTask",
              "datasync:DescribeLocation*"
          ],
          "Resource": "*"
      },
      {
          "Effect": "Allow",
          "Action": [
              "ec2:DescribeVpcs",
              "ec2:DescribeSubnets",
              "ec2:DescribeSecurityGroups",
              "ec2:DescribeNetworkInterfaces"
          ],
          "Resource": "*"
      },
      {
          "Effect": "Allow",
          "Action": [
              "outposts:ListOutposts",
              "outposts:GetOutpost"
          ],
          "Resource": "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "sts:AssumeRole"
        ],
        Resource = [
          "arn:aws:iam::${var.account_id}:role/secret_access",
          "arn:aws:iam::${var.account_id}:role/*/march_hare_encrypted-*"
        ]
      }
    ]
  })
}

//create a policy that has permissions to read flag from secretsmanager
resource "aws_iam_policy" "secret_access" {
  name        = "secret_access"
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
        "Resource" : aws_secretsmanager_secret.white-rabbit_flag2.arn
      }
    ]
  })
}

//attach the secret_access policy to cheshire_cat & terraform role
resource "aws_iam_role_policy_attachment" "attach_to_devrole" {
  role       = aws_iam_role.cheshire_cat.name
  policy_arn = aws_iam_policy.secret_access.arn
}

resource "aws_iam_role_policy_attachment" "attach_to_terraformrole" {
  role       = aws_iam_role.terraform.name
  policy_arn = aws_iam_policy.secret_access.arn
}

resource "aws_iam_user_policy_attachment" "attach_to_terraformuser" {
  user       = aws_iam_user.user["terraform"].name
  policy_arn = aws_iam_policy.secret_access.arn
}

resource "aws_iam_role" "devops" {
  name = "devops"

  assume_role_policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
  EOF

  tags = {
    Name        = "devops-role"
    Environment = "dev"
  }
}

# Optionally attach a managed policy to the role (e.g., EC2 read-only access)
resource "aws_iam_role_policy_attachment" "devops_policy_attachment" {
  role       = aws_iam_role.devops.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

//////////////////////////////////////////////////////////////////////

# IAM role and policy to allow Docker to push to ECR
resource "aws_iam_role" "ecr_push_role" {
  name = "ecr_push_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Effect    = "Allow"
        Sid       = ""
      }
    ]
  })
}

resource "aws_iam_policy" "ecr_push_policy" {
  name        = "ecr_push_policy"
  description = "Allow push to ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Effect   = "Allow"
        Resource = local.ecr_repository_arns
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ecr_push_policy_to_ecr_push_role" {
  role       = aws_iam_role.ecr_push_role.name
  policy_arn = aws_iam_policy.ecr_push_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_ecr_push_policy_to_cheshire_cat" {
  role       = aws_iam_role.cheshire_cat.name
  policy_arn = aws_iam_policy.ecr_push_policy.arn
}


//flag3 stored in buckets
resource "aws_s3_bucket" "white-rabbit-flag3" {
  bucket = "white-rabbit-flag3-${random_string.resource-suffix.result}"
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.white-rabbit-flag3.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "white-rabbit-flag3-public-access-block" {
  bucket = aws_s3_bucket.white-rabbit-flag3.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

// upload a file to the bucket.
resource "aws_s3_object" "white-rabbit-flag3-object" {
  bucket = aws_s3_bucket.white-rabbit-flag3.id
  key    = "flag.txt"
  source = "${path.module}/data/s3/flag.txt"
}

// Bucket Policy (deny everyone except roles starting with dev_encrypted)
resource "aws_s3_bucket_policy" "deny_except_role_prefix" {
  bucket = aws_s3_bucket.white-rabbit-flag3.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "DenyAllExceptEncryptedRoles",
        Effect    = "Deny",
        Principal = "*",
        Action    = "s3:*",
        Resource  = [
          aws_s3_bucket.white-rabbit-flag3.arn,
          "${aws_s3_bucket.white-rabbit-flag3.arn}/*"
        ],
        Condition = {
          StringNotLikeIfExists = {
            "aws:PrincipalArn" = [
              "arn:aws:iam::${var.account_id}:role/encryption/march_hare_encrypted-*",
              "arn:aws:iam::${var.account_id}:role/aws-reserved/sso.amazonaws.com/*/AWSReservedSSO_",
              "arn:aws:sts::${var.account_id}:assumed-role/AWSReservedSSO_*",
              "arn:aws:iam::${var.account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_*",
              "${var.aws_assume_role_arn}"
            ]
          }
        }
      }
    ]
  })
}

// create caterpillar role
resource "aws_iam_role" "caterpillar" {
  name = "caterpillar"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      for arn in [
        "arn:aws:iam::${var.account_id}:role/alice",
        "arn:aws:iam::${var.account_id}:role/cheshire_cat",
        "arn:aws:iam::${var.account_id}:role/queen_of_hearts"
      ] : {
        Effect = "Allow",
        Principal = {
          AWS = arn
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  permissions_boundary = "arn:aws:iam::${var.account_id}:policy/iam_permissions_boundary"
}

resource "aws_iam_policy" "iam_permissions_boundary" {
  name = "iam_permissions_boundary"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowCreatingRolesWithS3Boundary",
        Effect = "Allow",
        Action = [
          "iam:CreateRole",
          "iam:PutRolePolicy",
          "iam:AttachRolePolicy",
          "iam:PassRole"
        ],
        Resource = [
          "arn:aws:iam::*:role/jabberwock/*",
          "arn:aws:iam::*:role/encrypted/*",
          "arn:aws:iam::*:role/encryption/*",
          "arn:aws:iam::*:role/encrypt/*",
          "arn:aws:iam::*:role/tweedledee/*",
          "arn:aws:iam::*:role/tweedledum/*"
        ],
        Condition = {
          StringEquals = {
            "iam:PermissionsBoundary" = aws_iam_policy.s3_permissions_boundary.arn
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "s3_permissions_boundary" {
  name = "s3_permissions_boundary"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowS3OnlyOnWhiteRabbitBuckets",
        Effect = "Allow",
        Action = "s3:*",
        Resource = [
          "arn:aws:s3:::white-rabbit-*",
          "arn:aws:s3:::white-rabbit-*/*"
        ]
      },
      {
        Sid    = "DenyEverythingElse",
        Effect = "Deny",
        NotAction = "s3:*",
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_policy" "caterpillar_management_limited" {
  name = "caterpillar"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Action": "ec2:*",
        "Effect": "Allow",
			  "Resource": "*",
			  "Condition": {
				  "StringEquals": {
					  "aws:ResourceTag/challenge": "white_rabbit"
				  }
			  }
        },
        {
          "Effect": "Allow",
          "Action": "elasticloadbalancing:*",
			    "Resource": "*",
			    "Condition": {
				    "StringEquals": {
					    "aws:ResourceTag/challenge": "white_rabbit"
				    }
			    }
        },
        {
          "Effect": "Allow",
          "Action": "cloudwatch:*",
			    "Resource": "*",
			    "Condition": {
				    "StringEquals": {
					    "aws:ResourceTag/challenge": "white_rabbit"
				    }
			    }
        },
        {
          "Effect": "Allow",
          "Action": "autoscaling:*",
			    "Resource": "*",
			    "Condition": {
				    "StringEquals": {
					    "aws:ResourceTag/challenge": "white_rabbit"
				    }
			    }
        },
        {
            "Effect": "Allow",
            "Action": "iam:CreateServiceLinkedRole",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:AWSServiceName": [
                        "autoscaling.amazonaws.com",
                        "ec2scheduled.amazonaws.com",
                        "elasticloadbalancing.amazonaws.com",
                        "spot.amazonaws.com",
                        "spotfleet.amazonaws.com",
                        "transitgateway.amazonaws.com"
                    ]
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "arn:aws:iam::${var.account_id}:role/${aws_iam_role.codebuild-test-service-role.arn}"
        },
              {
        "Effect" = "Allow",
        "Action" = [
          "iam:CreateRole",
          "iam:PutRolePolicy",
          "iam:AttachRolePolicy",
          "iam:PassRole"
        ],
        "Resource" = "arn:aws:iam::${var.account_id}:role/*"
      }
    ]
  })
}

//attach the caterpillar policy to the caterpillar role
 resource "aws_iam_role_policy_attachment" "caterpillar-attachment" {
   role       = aws_iam_role.caterpillar.name
   policy_arn = aws_iam_policy.caterpillar_management_limited.arn
 }

// create march_hare_encrypted role
resource "aws_iam_role" "march_hare_encrypted-ewrfhovhu" {
  name = "march_hare_encrypted-ewrfhovhu"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "*"
        },
        Action = "sts:AssumeRole",
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = "o-12345abcde"
          },
          StringLike = {
            "aws:PrincipalArn" = "arn:aws:iam::${var.account_id}:role/cheshire_cat"
        }
        }
      }
    ]
  })

}

//attach the caterpillar policy to the caterpillar role
 resource "aws_iam_role_policy_attachment" "march_hare_encrypted-ewrfhovhu-s3attachment" {
   role       = aws_iam_role.march_hare_encrypted-ewrfhovhu.name
   policy_arn = aws_iam_policy.s3_permissions_boundary.arn
 }



//Flag1 creation
resource "aws_iam_role" "codebuild-test-service-role" {
  name = "codebuild-test-service-role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "codebuild.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
})
}

resource "aws_iam_policy" "CodeBuildBasePolicy-test" {
  name = "CodeBuildBasePolicy-test"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:logs:${var.AWS_REGION}:${var.account_id}:log-group:/aws/codebuild/test-codebuild-project",
                "arn:aws:logs:${var.AWS_REGION}:${var.account_id}:log-group:/aws/codebuild/test-codebuild-project:*"
            ],
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::codepipeline-${var.AWS_REGION}-*"
            ],
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:GetBucketAcl",
                "s3:GetBucketLocation"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "codebuild:CreateReportGroup",
                "codebuild:CreateReport",
                "codebuild:UpdateReport",
                "codebuild:BatchPutTestCases",
                "codebuild:BatchPutCodeCoverages"
            ],
            "Resource": [
                "arn:aws:codebuild:${var.AWS_REGION}:${var.account_id}:report-group/test-codebuild-project*"
            ]
        },
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
        "Resource" : aws_secretsmanager_secret.white-rabbit_flag1.arn
      }
    ]
})
}

resource "aws_iam_role_policy_attachment" "codebuild-test-service-role-codebuildattach" {
  role       = aws_iam_role.codebuild-test-service-role.name
  policy_arn = aws_iam_policy.CodeBuildBasePolicy-test.arn
}

# CHANGE ME TO RESTRICT ACCESS
resource "aws_iam_role_policy_attachment" "codebuild_s3_access" {
  role       = aws_iam_role.codebuild-test-service-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_policy" "queen-of-hearts" {
  name = "queen-of-hearts"
  policy = jsonencode({
    "Statement": [
        {
            "Sid": "AWSServicesAccess",
            "Action": [
                "codebuild:StartBuild",
                "codebuild:StopBuild",
                "codebuild:StartBuildBatch",
                "codebuild:StopBuildBatch",
                "codebuild:RetryBuild",
                "codebuild:RetryBuildBatch",
                "codebuild:BatchGet*",
                "codebuild:GetResourcePolicy",
                "codebuild:DescribeTestCases",
                "codebuild:DescribeCodeCoverages",
                "codebuild:List*",
                "codecommit:GetBranch",
                "codecommit:GetCommit",
                "codecommit:GetRepository",
                "codecommit:ListBranches",
                "cloudwatch:GetMetricStatistics",
                "events:DescribeRule",
                "events:ListTargetsByRule",
                "events:ListRuleNamesByTarget",
                "logs:GetLogEvents",
                "s3:GetBucketLocation",
                "s3:ListAllMyBuckets"
            ],
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Sid": "SSMParameterWriteAccess",
            "Effect": "Allow",
            "Action": [
                "ssm:PutParameter"
            ],
            "Resource": "arn:aws:ssm:*:*:parameter/CodeBuild/*"
        },
        {
            "Sid": "SSMStartSessionAccess",
            "Effect": "Allow",
            "Action": [
                "ssm:StartSession"
            ],
            "Resource": "arn:aws:ecs:*:*:task/*/*"
        },
        {
            "Sid": "CodeStarConnectionsUserAccess",
            "Effect": "Allow",
            "Action": [
                "codestar-connections:ListConnections",
                "codestar-connections:GetConnection"
            ],
            "Resource": [
                "arn:aws:codestar-connections:*:*:connection/*",
                "arn:aws:codeconnections:*:*:connection/*"
            ]
        },
        {
            "Sid": "CodeStarNotificationsReadWriteAccess",
            "Effect": "Allow",
            "Action": [
                "codestar-notifications:CreateNotificationRule",
                "codestar-notifications:DescribeNotificationRule",
                "codestar-notifications:UpdateNotificationRule",
                "codestar-notifications:Subscribe",
                "codestar-notifications:Unsubscribe"
            ],
            "Resource": "*",
            "Condition": {
                "ArnLike": {
                    "codestar-notifications:NotificationsForResource": "arn:aws:codebuild:*:*:project/*"
                }
            }
        },
        {
            "Sid": "CodeStarNotificationsListAccess",
            "Effect": "Allow",
            "Action": [
                "codestar-notifications:ListNotificationRules",
                "codestar-notifications:ListEventTypes",
                "codestar-notifications:ListTargets",
                "codestar-notifications:ListTagsforResource"
            ],
            "Resource": "*"
        },
        {
            "Sid": "SNSTopicListAccess",
            "Effect": "Allow",
            "Action": [
                "sns:ListTopics",
                "sns:GetTopicAttributes"
            ],
            "Resource": "*"
        },
        {
            "Sid": "CodeStarNotificationsChatbotAccess",
            "Effect": "Allow",
            "Action": [
                "chatbot:DescribeSlackChannelConfigurations",
                "chatbot:ListMicrosoftTeamsChannelConfigurations"
            ],
            "Resource": "*"
        }
    ],
    "Version": "2012-10-17"
})
}

resource "aws_iam_role_policy_attachment" "queen-of-heartsattach" {
  role       = aws_iam_role.queen_of_hearts.name
  policy_arn = aws_iam_policy.queen-of-hearts.arn
}

# CodeBuild Project
resource "aws_codebuild_project" "test" {
  name         = "test-codebuild-project"
  description  = "Test project with proper role"
  service_role = aws_iam_role.codebuild-test-service-role.arn

  source {
    type      = "S3"
    location  = "${aws_s3_bucket.codebuild-deployment.bucket}/my-source.zip" # Replace with actual bucket/key
    buildspec = <<EOF
version: 0.2

phases:
  build:
    commands:
      - echo "Running build..."
      - echo "Build complete."
artifacts:
  files:
    - '**/*'
EOF
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:6.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = false
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }
}

//create S3 bucket for codebuild
resource "aws_s3_bucket" "codebuild-deployment" {
  bucket = "codebuild-deployment-${random_string.resource-suffix.result}"
  force_destroy = true
#  region = "${var.AWS_REGION}"
  tags = {
    Name        = "codebuild-deployment-${random_string.resource-suffix.result}"
  }
}

resource "aws_s3_bucket_public_access_block" "codebuild-deployment-public-access-block" {
  bucket = aws_s3_bucket.codebuild-deployment.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

// upload code to the bucket.
resource "aws_s3_object" "codebuild-deployment-object" {
  bucket = aws_s3_bucket.codebuild-deployment.id
  key    = "my-source.zip"
  source = "${path.module}/data/s3/my-source.zip"
}

//create white rabbit flag1 in secretsmanager
resource "aws_secretsmanager_secret" "white-rabbit_flag1" {
  name                    = "white-rabbit_flag1"
  recovery_window_in_days = 0
  tags = {
    Name = "white rabbit flag1"
  }

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "WhiteRabbitFlag1",
        Effect   = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:role/codebuild-test-service-role"
        },
        Action   = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = "*"
      },
      {
        Sid    = "DenyEveryoneElse",
        Effect = "Deny",
        Principal = "*",
        Action   = "*",
        Resource = "*",
        Condition = {
          StringNotLikeIfExists = {
            "aws:PrincipalArn" = [
              "arn:aws:iam::${var.account_id}:role/codebuild-test-service-role",
              "arn:aws:iam::${var.account_id}:role/aws-reserved/sso.amazonaws.com/*/AWSReservedSSO_",
              "arn:aws:sts::${var.account_id}:assumed-role/AWSReservedSSO_*",
              "arn:aws:iam::${var.account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_*",
              "${var.aws_assume_role_arn}"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_secretsmanager_secret_version" "white-rabbit_flag1" {
  secret_id     = aws_secretsmanager_secret.white-rabbit_flag1.id
  secret_string = <<EOF
Curtsey while you're thinking. It saves time.

FLAG1{CodeCommitCanBeUsedToExecuteAWS}
EOF
}
