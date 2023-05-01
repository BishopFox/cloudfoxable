resource "aws_elasticsearch_domain" "example" {
  domain_name           = "example"
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
        "Action" = "es:*"
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

output "domain_endpoint" {
  value = aws_elasticsearch_domain.example.endpoint
}

resource "null_resource" "upload_logs" {
  triggers = {
    domain_endpoint = aws_elasticsearch_domain.example.endpoint
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -X POST "${aws_elasticsearch_domain.example.endpoint}/webserver-logs/_doc/" -H 'Content-Type: application/json' -d '{"timestamp": "2023-04-25T01:02:00Z", "log": "192.0.2.44 - - [25/Apr/2023:01:02:00 +0000] \"GET /app/database HTTP/1.1\" 200 7189", "source_ip": "192.0.2.44"}' && \
      curl -X POST "${aws_elasticsearch_domain.example.endpoint}/webserver-logs/_doc/" -H 'Content-Type: application/json' -d '{"timestamp": "2023-04-25T01:00:00Z", "log": "192.0.2.42 - - [25/Apr/2023:01:04:00 +0000] \"GET /app/login?session_id=abc123&ctf_flag=FLAG{You_will_find_the_craziest_stuff_in_elasticsearch_sometimes} HTTP/1.1\" 200 5123", "source_ip": "192.0.2.4"}' && \
      curl -X POST "${aws_elasticsearch_domain.example.endpoint}/webserver-logs/_doc/" -H 'Content-Type: application/json' -d '{"timestamp": "2023-04-25T01:01:00Z", "log": "192.0.2.43 - - [25/Apr/2023:01:01:00 +0000] \"GET /app/data?key_id=${aws_iam_access_key.Xavi.id}&access_key=${aws_iam_access_key.Xavi.secret} HTTP/1.1\" 200 6145", "source_ip": "192.0.2.43"}' && \
      curl -X POST "${aws_elasticsearch_domain.example.endpoint}/webserver-logs/_doc/" -H 'Content-Type: application/json' -d '{"timestamp": "2023-04-25T01:02:00Z", "log": "192.0.2.44 - - [25/Apr/2023:01:02:00 +0000] \"GET /app/profile HTTP/1.1\" 200 7189", "source_ip": "192.0.2.44"}'
    EOT
  }
}


resource "aws_iam_user" "Xavi" {
  name = "Xavi"
  force_destroy = true
}

resource "aws_iam_access_key" "Xavi" {
  user = aws_iam_user.Xavi.name
}



resource "aws_iam_user_policy" "Xavi" {
  name = "Xavi"
  user = aws_iam_user.Xavi.name

  policy = jsonencode({
    "Version" = "2012-10-17"
    "Statement" = [
      {
        "Effect" = "Allow"
        "Action" = [
          "dynamodb:GetItem",
          "dynamodb:BatchGetItem",
          "dynamodb:Query",
          "dynamodb:Scan",

        ]
        "Resource" = [
          "${aws_dynamodb_table.example.arn}",
        ]
      }
    ]
  })
}

// attach the xavi user to the policy

resource "aws_iam_user_policy_attachment" "Xavi" {
  user       = aws_iam_user.Xavi.name
  policy_arn = aws_iam_user_policy.Xavi.arn
}


resource "aws_dynamodb_table" "example" {
  name           = "example-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "null_resource" "insert_records" {
  depends_on = [aws_dynamodb_table.example]

  provisioner "local-exec" {
    command = <<-EOT
      aws --region "${var.AWS_REGION}" --profile "${var.aws_local_profile}" dynamodb put-item --table-name ${aws_dynamodb_table.example.name} --item '{"id": {"S": "record1"}, "data": {"S": "Sample data 1"}}' && \
      aws --region "${var.AWS_REGION}" --profile "${var.aws_local_profile}" dynamodb put-item --table-name ${aws_dynamodb_table.example.name} --item '{"id": {"S": "record2"}, "data": {"S": "Sample data 2"}, "ctf_flag": {"S": "FLAG{So_Many_DBs_To_Look_Through}"}}' && \
      aws --region "${var.AWS_REGION}" --profile "${var.aws_local_profile}" dynamodb put-item --table-name ${aws_dynamodb_table.example.name} --item '{"id": {"S": "record3"}, "data": {"S": "Sample data 3"}}'
    EOT
  }
}
