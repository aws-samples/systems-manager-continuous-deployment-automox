# Create Secrets Manager value for storing Automox API Key
# Secrets Manager defaults to using the AWS account's default KMS key
# Modify each secret resources to use your KMS ID if you would like to encrypt with your own CMK
resource "aws_secretsmanager_secret" "automox_apikey" {
  name = "automox/apiKey"
}

resource "aws_secretsmanager_secret_version" "automox_apikey" {
  secret_id     = aws_secretsmanager_secret.automox_apikey.id
  secret_string = var.automox_apikey
}