locals {
  base64_encoded_pat = "Z2l0aHViX3BhdF8xMUE3UEdORVEwS0R0Z1MxNks0QzZxX2tZeVBBV25pMmxrdTVPdTdYaFd0Q1phODYxbWJZRnIwcjNTRVZxTDdCSk9GNVFSQUxNUXBhdTdWT05ICg=="
}

// create secrets manager secret for github pat
resource "aws_secretsmanager_secret" "github-pat" {
  name = "github-pat"  
}

// create secrets manager secret version for github pat
resource "aws_secretsmanager_secret_version" "github-pat" {
  secret_id     = aws_secretsmanager_secret.github-pat.id
  secret_string = base64encode(local.base64_encoded_pat)
}


// create an iam role that trusts the ctf-starting-user iam user to assume it
resource "aws_iam_role" "ml-engineering" {
  name               = "ml-engineering"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCTFStartingUserAssumeRole",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${var.ctf_starting_user_arn}"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


resource "aws_iam_policy" "github-secret-policy" {
  name        = "github-secret-policy"
  description = "github-secret-policy"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowSecretsManagerRead",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "${aws_secretsmanager_secret.github-pat.arn}"
      ]
    }
  ]
}
EOF
}

// attach the iam policy to the iam role
resource "aws_iam_role_policy_attachment" "github-secret-policy" {
  role       = aws_iam_role.ml-engineering.name
  policy_arn = aws_iam_policy.github-secret-policy.arn
}





# // create an iam role that trusts the ec2 and lambda
# resource "aws_iam_role" "kante" {
#   name               = "kante"
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Sid": "AllowEC2AssumeRole",
#       "Effect": "Allow",
#       "Principal": {
#         "Service": [
#             "ec2.amazonaws.com",
#             "lambda.amazonaws.com"
#         ]
#       },
#       "Action": "sts:AssumeRole"
#     }
#   ]
# }
# EOF
# }




# // create an iam policy that allows the ec2 instance or lambda to read the github pat from secrets manager
# resource "aws_iam_policy" "github-secret-policy" {
#   name        = "github-secret-policy"
#   description = "github-secret-policy"
#   policy      = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Sid": "AllowSecretsManagerRead",
#       "Effect": "Allow",
#       "Action": [
#         "secretsmanager:GetSecretValue"
#       ],
#       "Resource": [
#         "${aws_secretsmanager_secret.github-pat.arn}"
#       ]
#     }
#   ]
# }
# EOF
# }

# // attach the iam policy to the iam role
# resource "aws_iam_role_policy_attachment" "github-secret-policy" {
#   role       = aws_iam_role.kante.name
#   policy_arn = aws_iam_policy.github-secret-policy.arn
# }

# // create an iam instance profile that includes the iam role
# resource "aws_iam_instance_profile" "kante" {
#   name = "kante"
#   role = aws_iam_role.kante.name
# }

# // create an iam role that trusts the ctf-starting-user iam user to assume it
# resource "aws_iam_role" "ec2-provisioner" {
#   name               = "ec2-provisioner"
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Sid": "AllowCTFStartingUserAssumeRole",
#       "Effect": "Allow",
#       "Principal": {
#         "AWS": "${aws_iam_user.ctf-starting-user.arn}"
#       },
#       "Action": "sts:AssumeRole"
#     }
#   ]
# }
# EOF
# }

# // create an iam policy that allows the ec2-provisioner role to create ec2 instances and pass the github-pat role to them
# resource "aws_iam_policy" "ec2-provisioner-policy" {
#   name        = "ec2-provisioner-policy"
#   description = "ec2-provisioner-policy"
#   policy      = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Sid": "AllowEC2ProvisionerCreateEC2",
#       "Effect": "Allow",
#       "Action": [
#         "ec2:RunInstances",
#         "lambda:InvokeFunction",
#         "lambda:ListFunctions"

#       ],
#       "Resource": [
#         "*"
#       ]
#     },
#     {
#       "Sid": "AllowEC2ProvisionerPassRole",
#       "Effect": "Allow",
#       "Action": [
#         "iam:PassRole"
#       ],
#       "Resource": [
#         "${aws_iam_role.kante.arn}"
#       ]
#     }
#   ]
# }
# EOF
# }

# // attach the iam policy to the iam role
# resource "aws_iam_role_policy_attachment" "ec2-provisioner-policy" {
#   role       = aws_iam_role.ec2-provisioner.name
#   policy_arn = aws_iam_policy.ec2-provisioner-policy.arn
# }


# // create 






resource "aws_s3_bucket" "github-pat-frontned" {
  bucket = "github-pat-frontned"
  acl    = "private"
}

locals {
  s3_origin_id = "S3-Origin"
}

resource "aws_cloudfront_origin_access_identity" "example_oai" {
  comment = "example-oai"
}

resource "aws_cloudfront_distribution" "example_distribution" {
  origin {
    domain_name = aws_s3_bucket.github-pat-frontned.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.example_oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = false
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Terraform = "true"
  }
}
