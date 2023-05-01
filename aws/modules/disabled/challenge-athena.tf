locals {
  json_data = <<EOT
{"id": 1, "first_name": "John", "last_name": "Doe", "email": "john.doe@example.com", "phone": "+1 555-123-4567", "address": {"street": "123 Main St", "city": "Anytown", "state": "CA", "zip_code": "12345"}, "social_security_number": "123-45-6789"}
{"id": 2, "first_name": "Jane", "last_name": "Doe", "email": "jane.doe@example.com", "phone": "+1 555-987-6543", "address": {"street": "456 Elm St", "city": "Anytown", "state": "CA", "zip_code": "12345"}, "social_security_number": "123-45-6788"}
{"id": 3, "first_name": "Bob", "last_name": "Smith", "email": "bob.smith@example.com", "phone": "+1 555-555-1212", "address": {"street": "789 Oak St", "city": "Othertown", "state": "CA", "zip_code": "54321"}, "social_security_number": "123-45-6787"}
{"id": 4, "first_name": "Alice", "last_name": "Johnson", "email": "alice.johnson@example.com", "phone": "+1 555-111-2222", "address": {"street": "321 Maple St", "city": "Smalltown", "state": "CA", "zip_code": "67890"}, "social_security_number": "123-45-6786"}
{"id": 5, "first_name": "Alex", "last_name": "Lee", "email": "alex.lee@example.com", "phone": "+1 555-222-3333", "address": {"street": "111 Pine St", "city": "Bigtown", "state": "CA", "zip_code": "54321"}, "social_security_number": "flag{IDontHaveAccessToS3ButIHaveAccessToAthena}"}
{"id": 6, "first_name": "Jane", "last_name": "Smith", "email": "jane.smith@example.com", "phone": "+1 555-444-5555", "address": {"street": "222 Oak St", "city": "Othertown", "state": "CA", "zip_code": "54321"}, "social_security_number": "123-45-6785"}
{"id": 7, "first_name": "George", "last_name": "Davis", "email": "george.davis@example.com", "phone": "+1 555-888-9999", "address": {"street": "333 Maple St", "city": "Smalltown", "state": "CA", "zip_code": "67890"}, "social_security_number": "123-45-6784"}
{"id": 8, "first_name": "Sara", "last_name": "Lopez", "email": "sara.lopez@example.com", "phone": "+1 555-333-4444", "address": {"street": "444 Pine St", "city": "Bigtown", "state": "CA", "zip_code": "54321"}
{"id": 9, "first_name": "David", "last_name": "Garcia", "email": "david.garcia@example.com", "phone": "+1 555-777-8888", "address": {"street": "555 Oak St", "city": "Othertown", "state": "CA", "zip_code": "54321"}, "social_security_number": "123-45-6783"}
{"id": 10, "first_name": "Mark", "last_name": "Nguyen", "email": "mark.nguyen@example.com", "phone": "+1 555-666-7777", "address": {"street": "666 Maple St", "city": "Smalltown", "state": "CA", "zip_code": "67890"}, "social_security_number": "123-45-6782"}
{"id": 11, "first_name": "Emily", "last_name": "Chen", "email": "emily.chen@example.com", "phone": "+1 555-555-4444", "address": {"street": "777 Pine St", "city": "Bigtown", "state": "CA", "zip_code": "54321"}, "social_security_number": "123-45-6781"}
{"id": 12, "first_name": "Samuel", "last_name": "Johnson", "email": "samuel.johnson@example.com", "phone": "+1 555-333-2222", "address": {"street": "888 Main St", "city": "Anytown", "state": "CA", "zip_code": "12345"}, "social_security_number": "123-45-6780"}
{"id": 13, "first_name": "Amy", "last_name": "Davis", "email": "amy.davis@example.com", "phone": "+1 555-111-0000", "address": {"street": "999 Elm St", "city": "Anytown", "state": "CA", "zip_code": "12345"}, "social_security_number": "123-45-6779"}
EOT
}


resource "aws_s3_bucket" "cloudfox-athena" {
  bucket = "cloudfox-athena"

}

resource "aws_s3_bucket_object" "example" {
  bucket = aws_s3_bucket.cloudfox-athena.id
  key    = "example-data/data.json"
  content = local.json_data
  acl     = "private"
}


resource "aws_s3_bucket" "cloudfox-athena-results" {
  bucket = "cloudfox-athena-results"
  acl    = "private"
}

resource "aws_glue_catalog_database" "example" {
  name = "your_database"
}

resource "aws_glue_catalog_table" "example" {
  name          = "your_table"
  database_name = aws_glue_catalog_database.example.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "classification" = "json"
  }

  storage_descriptor {
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.IgnoreKeyTextOutputFormat"

    ser_de_info {
      name = "example"
      parameters = {
        "serialization.format" = "1"
        "paths"                = "s3://your-unique-bucket-name/example-data/"
      }
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    location      = "s3://${aws_s3_bucket.cloudfox-athena.bucket}/example-data/"
    compressed    = false
    stored_as_sub_directories = false

    columns {
      name = "id"
      type = "int"
    }
    columns {
      name = "first_name"
      type = "string"
    }
    columns {
      name = "last_name"
      type = "string"
    }
    columns {
      name = "social_security_number"
      type = "string"
    }
    columns {
      name = "email"
      type = "string"
    }
    columns {
      name = "phone"
      type = "string"
    }
    columns {
      name = "address"
      type = "struct<street:string,city:string,state:string,zip_code:string>"
    }
  }
}

resource "aws_athena_workgroup" "example" {
  name = "example_workgroup"
  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.cloudfox-athena-results.bucket}/query-results/"
    }
  }
}

// create an iam user that has access to make queries in athena
resource "aws_iam_user" "athena-user" {
  name = "athena-user"
}

// create a policy that allows this user to make queries in athena

resource "aws_iam_policy" "athena-user" {
  name        = "athena-user"
  description = "athena-user"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowAthena",
      "Effect": "Allow",
      "Action": [
        "athena:StartQueryExecution",
        "athena:GetQueryExecution",
        "athena:GetQueryResults",
        "athena:StopQueryExecution"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

// attach the policy to the user
resource "aws_iam_user_policy_attachment" "athena-user" {
  user       = aws_iam_user.athena-user.name
  policy_arn = aws_iam_policy.athena-user.arn
}

// create an access key for the user
resource "aws_iam_access_key" "athena-user-key" {
  user = aws_iam_user.athena-user.name
}

// output the access key and secret key
output "athena_access_key" {
  value = aws_iam_access_key.athena-user-key.id
}

output "athena_secret_key" {
  value = aws_iam_access_key.athena-user-key.secret
}



