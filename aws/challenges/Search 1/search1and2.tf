locals {
  base64_encoded_pat = "Z2l0aHViX3BhdF8xMUE3UEdORVEwUHhZTFNNNm1MWnplXzlTZnBDeFVZV0ZycXJEMlp0V2NZZjRySmFEYkNKMXQ5S0VCUWNOUUM5VjNSUElZT1VST0sxQzl5WTdKCg=="
}

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
      curl -X POST "${aws_elasticsearch_domain.pat.endpoint}/webserver-logs/_doc/" -H 'Content-Type: application/json' -d '{"timestamp": "2023-04-25T01:00:00Z", "log": "192.0.2.42 - - [25/Apr/2023:01:04:00 +0000] \"GET /app/login?session_id=abc123&ctf_flag=FLAG{search1::You_will_find_the_craziest_stuff_in_elasticsearch_sometimes} HTTP/1.1\" 200 5123", "source_ip": "192.0.2.4"}' && \
      curl -X POST "${aws_elasticsearch_domain.pat.endpoint}/webserver-logs/_doc/" -H 'Content-Type: application/json' -d '{"timestamp": "2023-04-25T01:01:00Z", "log": "192.0.2.43 - - [25/Apr/2023:01:01:00 +0000] \"GET /app/data?token=${local.base64_encoded_pat} HTTP/1.1\" 200 6145", "source_ip": "192.0.2.43"}' && \
      curl -X POST "${aws_elasticsearch_domain.pat.endpoint}/webserver-logs/_doc/" -H 'Content-Type: application/json' -d '{"timestamp": "2023-04-25T01:02:00Z", "log": "192.0.2.44 - - [25/Apr/2023:01:02:00 +0000] \"GET /app/profile HTTP/1.1\" 200 7189", "source_ip": "192.0.2.44"}'
    EOT
  }
}

