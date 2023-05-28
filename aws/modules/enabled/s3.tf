

resource "aws_s3_bucket" "cloudfoxable-bucket1" {
  bucket = "cloudfoxable-bucket1-${random_string.resource-suffix.result}"
  force_destroy = true

  tags = {
    Name        = "bucket1-${random_string.resource-suffix.result}"
  }
}

# resource "aws_s3_bucket_acl" "cloudfoxable-bucket1-acl" {
#   bucket = aws_s3_bucket.cloudfoxable-bucket1.id

#   acl    = "private"
# }

resource "aws_s3_bucket" "cloudfoxable-bucket2" {
  bucket = "cloudfoxable-bucket2-${random_string.resource-suffix.result}"
    force_destroy = true


  tags = {
    Name        = "bucket2-${random_string.resource-suffix.result}"
  }
}

# resource "aws_s3_bucket_acl" "cloudfoxable-bucket2-acl" {
#   bucket = aws_s3_bucket.cloudfoxable-bucket2.id

#   acl    = "private"
# }

resource "aws_s3_bucket" "cloudfoxable-bucket3" {
  bucket = "cloudfoxable-bucket3-${random_string.resource-suffix.result}"
    force_destroy = true


  tags = {
    Name        = "bucket3-${random_string.resource-suffix.result}"
  }
}

# resource "aws_s3_bucket_acl" "cloudfoxable-bucket3-acl" {
#   bucket = aws_s3_bucket.cloudfoxable-bucket3.id
#   acl    = "private"
# }

# resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
#   bucket = aws_s3_bucket.cloudfoxable-bucket3.id
#   policy = data.aws_s3_policy_document.allow_access_from_another_account.json
# }


// create a bucket policy that allows anyone from account 111111111111111 to read from the bucket
# resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
#   bucket = aws_s3_bucket.cloudfoxable-bucket3.id

#   policy = <<POLICY
# {
#   "Version": "2012-10-17",
#   "Id": "user_updates",
#   "Statement": [
#     {
#       "Sid": "user_updates",
#       "Effect": "Allow",
#       "Principal": { 
#         "AWS": "arn:aws:iam::111111111111111:user/seth"        
#       },
#       "Action": [
#         "s3:GetObject",
#         "s3:ListBucket"
#       ],
#       "Resource": [
#         "${aws_s3_bucket.cloudfoxable-bucket3.arn}",
#         "${aws_s3_bucket.cloudfoxable-bucket3.arn}/*"
#       ]
#     }
#   ]
# }
# POLICY
# }
