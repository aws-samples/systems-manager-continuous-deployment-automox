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

# Grant the pre-existing EC2 instance profile read access to the Automox API key secret.
# The SSM document resolves the key at command-execution time on the instance
# (via {{resolve:secretsmanager:automox/apiKey}}), so the instance role needs GetSecretValue
# scoped to this specific secret.
data "aws_iam_policy_document" "automox_secret_read" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.automox_apikey.arn]
  }
}

resource "aws_iam_role_policy" "automox_secret_read" {
  name   = "automox-apikey-secret-read"
  role   = var.aws_ec2_instance_profile
  policy = data.aws_iam_policy_document.automox_secret_read.json
}
