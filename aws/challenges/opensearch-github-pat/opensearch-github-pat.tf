locals {
  base64_encoded_pat = "Z2l0aHViX3BhdF8xMUE3UEdORVEwS0R0Z1MxNks0QzZxX2tZeVBBV25pMmxrdTVPdTdYaFd0Q1phODYxbWJZRnIwcjNTRVZxTDdCSk9GNVFSQUxNUXBhdTdWT05ICg=="
}

# // create secrets manager secret for github pat
# resource "aws_secretsmanager_secret" "github-pat2" {
#   name = "github-pat2"  
# }

# // create secrets manager secret version for github pat
# resource "aws_secretsmanager_secret_version" "github-pat2" {
#   secret_id     = aws_secretsmanager_secret.github-pat2.id
#   secret_string = base64decode(local.base64_encoded_pat)
# }


resource "aws_elasticsearch_domain" "pat" {
  domain_name           = "pat"
  elasticsearch_version = "7.9"

  cluster_config {
    instance_type = "t2.small.elasticsearch"
    instance_count = 1
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
  }

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  access_policies = jsonencode({
    "Version" = "2012-10-17"
    "Statement" = [
      {
        "Effect" = "Allow"
        "Principal" = {
          "AWS" = "*"
        }
        "Action" = [
          "es:ESHttpGet",
          "es:ESHttpHead",
          "es:ESHttpPost"
        ]
      

        "Resource" = "*"
        "Condition" = {
          "IpAddress" = {
            "aws:SourceIp" = "${var.user_ip}/32"
          }
        }
      }
    ]
  })


}

output "pat_domain_endpoint" {
  value = aws_elasticsearch_domain.pat.endpoint
}

resource "null_resource" "upload_logs" {
  triggers = {
    pat_domain_endpoint = aws_elasticsearch_domain.pat.endpoint
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -X POST "${aws_elasticsearch_domain.pat.endpoint}/webserver-logs/_doc/" -H 'Content-Type: application/json' -d '{"timestamp": "2023-04-25T01:02:00Z", "log": "192.0.2.44 - - [25/Apr/2023:01:02:00 +0000] \"GET /app/database HTTP/1.1\" 200 7189", "source_ip": "192.0.2.44"}' && \
      curl -X POST "${aws_elasticsearch_domain.pat.endpoint}/webserver-logs/_doc/" -H 'Content-Type: application/json' -d '{"timestamp": "2023-04-25T01:00:00Z", "log": "192.0.2.42 - - [25/Apr/2023:01:04:00 +0000] \"GET /app/login?session_id=abc123&ctf_flag=FLAG{You_will_find_the_craziest_stuff_in_elasticsearch_sometimes} HTTP/1.1\" 200 5123", "source_ip": "192.0.2.4"}' && \
      curl -X POST "${aws_elasticsearch_domain.pat.endpoint}/webserver-logs/_doc/" -H 'Content-Type: application/json' -d '{"timestamp": "2023-04-25T01:01:00Z", "log": "192.0.2.43 - - [25/Apr/2023:01:01:00 +0000] \"GET /app/data?token=${local.base64_encoded_pat} HTTP/1.1\" 200 6145", "source_ip": "192.0.2.43"}' && \
      curl -X POST "${aws_elasticsearch_domain.pat.endpoint}/webserver-logs/_doc/" -H 'Content-Type: application/json' -d '{"timestamp": "2023-04-25T01:02:00Z", "log": "192.0.2.44 - - [25/Apr/2023:01:02:00 +0000] \"GET /app/profile HTTP/1.1\" 200 7189", "source_ip": "192.0.2.44"}'
    EOT
  }
}


# resource "aws_iam_user" "Ronaldinho" {
#   name = "Ronaldinho"
#   force_destroy = true
# }

# resource "aws_iam_access_key" "Ronaldinho" {
#   user = aws_iam_user.Ronaldinho.name
# }


# // create a policy that allows Ronaldinho to read the github pat secret
# resource "aws_iam_user_policy" "Ronaldinho" {
#   name = "Ronaldinho"
#   user = aws_iam_user.Ronaldinho.name

#   policy = jsonencode({
#     "Version" = "2012-10-17"
#     "Statement" = [
#       {
#         "Sid": "AllowSecretsManagerRead",
#         "Effect": "Allow",
#         "Action": [
#           "secretsmanager:GetSecretValue"
#         ],
#         "Resource": [
#           "${aws_secretsmanager_secret.github-pat2.arn}"
#         ]
        
#       }
#     ]
#   })
# }

# resource "aws_iam_user_policy_attachment" "Ronaldinho" {
#   user = aws_iam_user.Ronaldinho.name
#   policy_arn = aws_iam_user_policy.Ronaldinho.policy
# }



# resource "aws_iam_user_policy" "Ronaldinho" {
#   name = "Ronaldinho"
#   user = aws_iam_user.Ronaldinho.name

#   policy = jsonencode({
#     "Version" = "2012-10-17"
#     "Statement" = [
#       {
#         "Sid": "AllowSecretsManagerRead",
#         "Effect": "Allow",
#         "Action": [
#           "secretsmanager:GetSecretValue"
#         ],
#         "Resource": [
#           "${aws_secretsmanager_secret.github-pat2.arn}"
#         ]
        
#       }
#     ]
#   })
# }

# resource "aws_iam_user_policy_attachment" "Ronaldinho" {
#   user = aws_iam_user.Ronaldinho.name
#   policy_arn = aws_iam_user_policy.Ronaldinho.arn
# }








# // create an iam role that trusts the ctf-starting-user iam user to assume it
# resource "aws_iam_role" "ml-engineering" {
#   name               = "ml-engineering"
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Sid": "AllowCTFStartingUserAssumeRole",
#       "Effect": "Allow",
#       "Principal": {
#         "AWS": "${var.ctf_starting_user_arn}"
#       },
#       "Action": "sts:AssumeRole"
#     }
#   ]
# }
# EOF
# }


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
#         "${aws_secretsmanager_secret.github-pat2.arn}"
#       ]
#     }
#   ]
# }
# EOF
# }

# // attach the iam policy to the iam role
# resource "aws_iam_role_policy_attachment" "github-secret-policy" {
#   role       = aws_iam_role.ml-engineering.name
#   policy_arn = aws_iam_policy.github-secret-policy.arn
# }





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
#         "${aws_secretsmanager_secret.github-pat2.arn}"
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

# // create an iam policy that allows the ec2-provisioner role to create ec2 instances and pass the github-pat2 role to them
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






# resource "aws_s3_bucket" "github-pat2-frontned" {
#   bucket = "github-pat2-frontned"
#   acl    = "private"
# }

# locals {
#   s3_origin_id = "S3-Origin"
# }

# resource "aws_cloudfront_origin_access_identity" "pat_oai" {
#   comment = "pat-oai"
# }

# resource "aws_cloudfront_distribution" "pat_distribution" {
#   origin {
#     domain_name = aws_s3_bucket.github-pat2-frontned.bucket_regional_domain_name
#     origin_id   = local.s3_origin_id

#     s3_origin_config {
#       origin_access_identity = aws_cloudfront_origin_access_identity.pat_oai.cloudfront_access_identity_path
#     }
#   }

#   enabled             = true
#   is_ipv6_enabled     = false
#   default_root_object = "index.html"

#   default_cache_behavior {
#     allowed_methods  = ["GET", "HEAD"]
#     cached_methods   = ["GET", "HEAD"]
#     target_origin_id = local.s3_origin_id

#     forwarded_values {
#       query_string = false
#       cookies {
#         forward = "none"
#       }
#     }

#     viewer_protocol_policy = "redirect-to-https"
#     min_ttl                = 0
#     default_ttl            = 3600
#     max_ttl                = 86400
#   }

#   price_class = "PriceClass_100"

#   restrictions {
#     geo_restriction {
#       restriction_type = "none"
#     }
#   }

#   viewer_certificate {
#     cloudfront_default_certificate = true
#   }

#   tags = {
#     Terraform = "true"
#   }
# }
