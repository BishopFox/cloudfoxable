resource "aws_cloudformation_stack" "cloudformationStack" {
  name = "cloudformationStack"
  //iam_role_arn = aws_iam_role.cf-admin-role.arn
  capabilities = ["CAPABILITY_NAMED_IAM"]

  template_body = <<STACK
{
  "Resources" : {
    "Bucket1" : {
      "Type" : "AWS::S3::Bucket",
      "Properties" : {
        "BucketName" : "my-production-bucket-${random_string.resource-suffix.result}"
      }
    },
    "IAMRole1" : {
      "Type" : "AWS::IAM::Role",
      "Properties" : {
        "RoleName" : "my-app-role",
        "AssumeRolePolicyDocument" : {
          "Version": "2012-10-17",
          "Statement": [
            {
              "Effect": "Allow",
              "Principal": {
                "Service": "lambda.amazonaws.com"
              },
              "Action": "sts:AssumeRole"
            }
          ]
        }
      }
    },
    "DynamoDBTable1" : {
      "Type" : "AWS::DynamoDB::Table",
      "Properties" : {
        "TableName" : "my-user-profiles",
        "AttributeDefinitions" : [
          {
            "AttributeName" : "ID",
            "AttributeType" : "N"
          }
        ],
        "KeySchema" : [
          {
            "AttributeName" : "ID",
            "KeyType" : "HASH"
          }
        ],
        "ProvisionedThroughput" : {
          "ReadCapacityUnits" : 5,
          "WriteCapacityUnits" : 5
        }
      }
    },
    "DemoIAMGroup" : {
      "Type" : "AWS::IAM::Group",
      "Properties" : {
        "GroupName" : "USMNT"
      }
    },
    "DemoIAMGroup" : {
      "Type" : "AWS::IAM::Group",
      "Properties" : {
        "GroupName" : "USWNT"
      }
    },
    "DemoIAMRole" : {
      "Type" : "AWS::IAM::Role",
      "Properties" : {
        "RoleName" : "fox",
        "AssumeRolePolicyDocument" : {
          "Version" : "2012-10-17",
          "Statement": [ {
            "Effect": "Allow",
            "Principal": {
              "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
          } ]
        }
      }
    },
    "NotImportant" : {
      "Type" : "AWS::SecretsManager::Secret",
      "Properties" : {
        "Description" : "Secure secret for sensitive data",
        "Name" : "my-app-secret",
        "SecretString" : "FLAG{needles::hardcoded_secret_in_cloudformation}"
      }
    },
    "DemoIAMUser" : {
      "Type" : "AWS::IAM::User",
      "Properties" : {
        "UserName" : "demo-iam-user"
      }
    },
    "DemoIAMPolicy" : {
      "Type" : "AWS::IAM::Policy",
      "Properties" : {
        "PolicyName" : "demo-iam-policy",
        "PolicyDocument" : {
          "Version" : "2012-10-17",
          "Statement": [ {
            "Effect": "Allow",
            "Action": [ "s3:ListBucket" ],
            "Resource": [ "arn:aws:s3:::demo-${random_string.resource-suffix.result}" ]
          } ]
        },
        "Roles": [ { "Ref": "DemoIAMRole" } ]
      }
    }    
  }
}
STACK
}

// create iam role that is assumable by ctf_startin_user and can view cloudformation stacks
resource "aws_iam_role" "ramos" {
  name = "ramos"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "${var.ctf_starting_user_arn}"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

// attach policy to role that allows viewing cloudformation stacks
resource "aws_iam_role_policy_attachment" "role-policy-attachment3" {
  role       = aws_iam_role.ramos.name
  policy_arn = "arn:aws:iam::aws:policy/AWSWAFReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "role-policy-attachment2" {
  role       = aws_iam_role.ramos.name
  policy_arn = "arn:aws:iam::aws:policy/AWSBudgetsReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "role-policy-attachment1" {
  role       = aws_iam_role.ramos.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudFormationReadOnlyAccess"
}



