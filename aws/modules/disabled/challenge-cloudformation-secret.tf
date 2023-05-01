resource "aws_cloudformation_stack" "cloudformationStack" {
  name = "cloudformationStack"
  //iam_role_arn = aws_iam_role.cf-admin-role.arn
  //capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"]

  template_body = <<STACK
{
  "Resources" : {
    "Secret1" : {
      "Type" : "AWS::SecretsManager::Secret",
      "Properties" : {
          "Description" : "Super strong password that nobody would ever be able to guess",
          "Name" : "iam-vulnerable",
          "SecretString" : "flag{hardcoded_secret_in_cloudformation}"
      }
    }
  }
}
STACK
}

