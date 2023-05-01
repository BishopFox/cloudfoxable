// Entrypoint - starting-user has been given access to view this secret


resource "aws_secretsmanager_secret" "database-secret" {
  name                    = "database-secret"
  recovery_window_in_days = 0
  tags = {
    Name = "Database Secret"
  }

}

resource "aws_secretsmanager_secret_version" "database-secret" {
  secret_id     = aws_secretsmanager_secret.database-secret.id
  secret_string = random_password.database-secret.result
}

resource "aws_secretsmanager_secret" "app-secret" {
  name                    = "app-secret"
  recovery_window_in_days = 0
  tags = {
    Name = "App Secret"
  }

}

resource "aws_secretsmanager_secret_version" "app-secret" {
  secret_id     = aws_secretsmanager_secret.app-secret.id
  secret_string = "flag{always_look_what_secrets_you_have_access_to}"
}