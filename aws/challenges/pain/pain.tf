// create a role that can be assumed by the ctf starting user
resource "aws_iam_role" "pain" {
    name = "christian_pulisic"
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

# // attach the aws cloudformation full access policy to the role
# resource "aws_iam_role_policy_attachment" "pain-policy-attachment" {
#     role = aws_iam_role.pain.name
#     policy_arn = "arn:aws:iam::aws:policy/AWSCloudFormationFullAccess"
# }


// create a policy that allows the ctf starting user to create cloudformation stacks and to pass roles to them, but only roles that trust the cloudformation service
resource "aws_iam_policy" "pain-policy" {
    name = "pain-policy"
    policy = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
            {
                "Effect" : "Allow",
                "Action" : [
                    "cloudformation:CreateStack",
                    "cloudformation:DescribeStacks",
                    "cloudformation:DeleteStack",
                    "cloudformation:DescribeStackEvents",
                    "cloudformation:DescribeStackResource",
                    "cloudformation:DescribeStackResources",
                    "cloudformation:DescribeStacks"                   
                ],
                "Resource" : "*"
            },
            {
                "Effect" : "Allow",
                "Action" : [
                    "iam:PassRole"
                ],
                "Resource" : [
                    "*"
                ]
            }
        ]
    })
}

// attach the policy to the role
resource "aws_iam_role_policy_attachment" "pain-policy-attachment" {
    role = aws_iam_role.pain.name
    policy_arn = aws_iam_policy.pain-policy.arn
}

// attach a managed policy to pulisic that allows pulisic read only to ec2 things
resource "aws_iam_role_policy_attachment" "pulisic-ec2-policy-attachment" {
    role = aws_iam_role.pain.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}


// attach a managed policy to pulisic that allows pulisic read only to cloudformation things
resource "aws_iam_role_policy_attachment" "pulisic-cloudformation-policy-attachment" {
    role = aws_iam_role.pain.name
    policy_arn = "arn:aws:iam::aws:policy/AWSCloudFormationReadOnlyAccess"
}

// attach a managed policy to pulisic that allows pulisic read only to opsworks things
resource "aws_iam_role_policy_attachment" "pulisic-opsworks-policy-attachment" {
    role = aws_iam_role.pain.name
    policy_arn = "arn:aws:iam::aws:policy/AWSOpsWorksCMInstanceProfileRole"
}




// create a role that trusts the cloudformation service
resource "aws_iam_role" "pain2" {
    name = "tab_ramos"
    assume_role_policy = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
            {
                "Effect" : "Allow",
                "Principal" : {
                    "Service" : [
                        "cloudformation.amazonaws.com"
                    ]
                },
                "Action" : [
                    "sts:AssumeRole"
                ]
            }
        ]
    })
}

 // attach the lambda full access policy to the role
resource "aws_iam_role_policy_attachment" "pain2-policy-attachment" {
    role = aws_iam_role.pain2.name
    policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}

// create a policy that will deny iam passrole to specific iam role arns
resource "aws_iam_policy" "pain2-deny-policy" {
    name = "pain2-policy"
    policy = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
            {
                "Effect" : "Deny",
                "Action" : [
                    "iam:PassRole"
                ],
                "Resource" : [
                    "arn:aws:iam::*:role/aaronson",
                    "arn:aws:iam::*:role/my-app-role",
                    "arn:aws:iam::*:role/producer",
                    "arn:aws:iam::*:role/ream",
                    "arn:aws:iam::*:role/sauerbrunn",
                    "arn:aws:iam::*:role/swanson",
                    "arn:aws:iam::*:role/lambda_*"
                ]
            }
        ]
    })
}

//attach pain2-deny-policy to tab ramos
resource "aws_iam_role_policy_attachment" "pain2-deny-policy-attachment" {
    role = aws_iam_role.pain2.name
    policy_arn = aws_iam_policy.pain2-deny-policy.arn
}



// create a role that trusts the lambda service

resource "aws_iam_role" "pain3" {
    name = "brian_mcbride"
    assume_role_policy = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
            {
                "Effect" : "Allow",
                "Principal" : {
                    "Service" : [
                        "lambda.amazonaws.com"
                    ]
                },
                "Action" : [
                    "sts:AssumeRole"
                ]
            }
        ]
    })
}

// create a policy that allows the lambda function to create create an ec2 instance and pass a role to it
resource "aws_iam_policy" "pain3-ec2-policy" {
    name = "pain3-ec2-policy"
    policy = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
            {
                "Effect" : "Allow",
                "Action" : [
                    "ec2:RunInstances",
                    "ec2:DescribeInstances",
                    "ec2:TerminateInstances",
                    "ec2:Describe*",
                ],
                "Resource" : "*"
            },
            {
                "Effect" : "Allow",
                "Action" : [
                    "iam:PassRole"
                ],
                "Resource" : "*"
            },
            {
                "Effect" : "Deny",
                "Action" : [
                    "iam:PassRole"
                ],
                "Resource" : [
                    "arn:aws:iam::*:role/double_*",
                    "arn:aws:iam::*:role/ec2_privileged",
                    "arn:aws:iam::*:role/fox",
                    "arn:aws:iam::*:role/wyatt",
                    "arn:aws:iam::*:role/reyna"
                ]
            }
        ]
    })
}

// attach the policy to the role
resource "aws_iam_role_policy_attachment" "pain3-policy-attachment" {
    role = aws_iam_role.pain3.name
    policy_arn = aws_iam_policy.pain3-ec2-policy.arn
}

// attach AWSLambdaBasicExecutionRole to brian_mcbride
resource "aws_iam_role_policy_attachment" "pain3-lambda-policy-attachment" {
    role = aws_iam_role.pain3.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


// create a role that trusts the ec2 service
resource "aws_iam_role" "pain4" {
    name = "landon_donovan"
    assume_role_policy = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
            {
                "Effect" : "Allow",
                "Principal" : {
                    "Service" : [
                        "ec2.amazonaws.com"
                    ]
                },
                "Action" : [
                    "sts:AssumeRole"
                ]
            }
        ]
    })
}

// create an instance profile for the role
resource "aws_iam_instance_profile" "pain4-instance-profile" {
    name = "landon_donovan"
    role = aws_iam_role.pain4.name
}

// create an s3 bucket that will hold the flag
resource "aws_s3_bucket" "pain-s3" {
    bucket = "pain-s3-${random_string.resource-suffix.result}"
}

// create a policy that allows the ec2 instance to read the flag from the s3 bucket and also allows the ec2 instance to list all files in the bucket
resource "aws_iam_policy" "pain4-policy" {
    name = "pain4-policy"
    policy = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
            {
                "Effect" : "Allow",
                "Action" : [
                    "s3:GetObject",
                    "s3:ListBucket"
                ],
                "Resource" : [
                    "${aws_s3_bucket.pain-s3.arn}",
                    "${aws_s3_bucket.pain-s3.arn}/*"
                ]
            },
            {
                "Effect" : "Allow",
                "Action" : [
                    "s3:ListAllMyBuckets"
                ],
                "Resource" : [
                    "*"
                ]
            }
        ]        
    })
}

// attach the policy to the role
resource "aws_iam_role_policy_attachment" "pain4-policy-attachment" {
    role = aws_iam_role.pain4.name
    policy_arn = aws_iam_policy.pain4-policy.arn
}

// attach administrator access policy to landon donovan
# resource "aws_iam_role_policy_attachment" "pain4-admin-policy-attachment" {
#     role = aws_iam_role.pain4.name
#     policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
# }



// upload the flag to the s3 bucket
resource "aws_s3_object" "pain-s3-object" {
    bucket = aws_s3_bucket.pain-s3.id
    key = "flag.txt"
    source = "challenges/pain/data/flag.txt"
}

