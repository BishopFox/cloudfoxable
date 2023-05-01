resource "aws_ecr_repository" "node-ssrf-app" {
  name                 = "node-ssrf-app-${random_string.resource-suffix.result}"
  image_tag_mutability = "MUTABLE"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = false
  }
}
