# resource "aws_ram_resource_share" "example" {
#   # ... other configuration ...
#   allow_external_principals = true
# }

# resource "aws_ram_principal_association" "example" {
#   principal          = "111111111111"
#   resource_share_arn = aws_ram_resource_share.example.arn
# }