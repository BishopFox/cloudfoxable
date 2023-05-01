

resource "aws_s3_bucket" "cloudfox-bucket1" {
  bucket = "cloudfox-bucket1-${random_string.resource-suffix.result}"
  force_destroy = true

  tags = {
    Name        = "bucket1-${random_string.resource-suffix.result}"
  }
}

resource "aws_s3_bucket_acl" "cloudfox-bucket1-acl" {
  bucket = aws_s3_bucket.cloudfox-bucket1.id

  acl    = "private"
}

resource "aws_s3_bucket" "cloudfox-bucket2" {
  bucket = "cloudfox-bucket2-${random_string.resource-suffix.result}"
    force_destroy = true


  tags = {
    Name        = "bucket2-${random_string.resource-suffix.result}"
  }
}

resource "aws_s3_bucket_acl" "cloudfox-bucket2-acl" {
  bucket = aws_s3_bucket.cloudfox-bucket2.id

  acl    = "private"
}

resource "aws_s3_bucket" "cloudfox-bucket3" {
  bucket = "cloudfox-bucket3-${random_string.resource-suffix.result}"
    force_destroy = true


  tags = {
    Name        = "bucket3-${random_string.resource-suffix.result}"
  }
}

resource "aws_s3_bucket_acl" "cloudfox-bucket3-acl" {
  bucket = aws_s3_bucket.cloudfox-bucket3.id
  acl    = "private"
}

# resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
#   bucket = aws_s3_bucket.cloudfox-bucket3.id
#   policy = data.aws_s3_policy_document.allow_access_from_another_account.json
# }


// create a bucket policy that allows anyone from account 89507344597 to read from the bucket
# resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
#   bucket = aws_s3_bucket.cloudfox-bucket3.id

#   policy = <<POLICY
# {
#   "Version": "2012-10-17",
#   "Id": "user_updates",
#   "Statement": [
#     {
#       "Sid": "user_updates",
#       "Effect": "Allow",
#       "Principal": { 
#         "AWS": "arn:aws:iam::89507344597:user/seth"        
#       },
#       "Action": [
#         "s3:GetObject",
#         "s3:ListBucket"
#       ],
#       "Resource": [
#         "${aws_s3_bucket.cloudfox-bucket3.arn}",
#         "${aws_s3_bucket.cloudfox-bucket3.arn}/*"
#       ]
#     }
#   ]
# }
# POLICY
# }
