provider "aws" {
  region = var.aws_region
}

# Creates Automox installation Logging bucket.
# This bucket is not needed if using in a best practice multi-account strategy environment. 
# In a Landing Zone or Control Tower environment, point the SSM Association to output to your Log Archive account bucket. 
# This S3 bucket does not have access logging enabled to avoid recursive logging
resource "aws_s3_bucket" "s3_automox_log_bucket" {
  bucket        = var.aws_s3_automox_log_bucket
  force_destroy = true

  tags = {
    Name = "${var.aws_s3_automox_log_bucket}"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_automox_log_bucket_enc" {
  bucket = aws_s3_bucket.s3_automox_log_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "allow_access_from_ec2_instance_profile" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:role/${var.aws_ec2_instance_profile}"]
    }

    actions = [
      "s3:PutObject",
      "s3:ListBucket",
      "s3:GetObject"
    ]

    resources = [
      aws_s3_bucket.s3_automox_log_bucket.arn,
      "${aws_s3_bucket.s3_automox_log_bucket.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "allow_access_from_ec2_instance_profile" {
  bucket = aws_s3_bucket.s3_automox_log_bucket.id
  policy = data.aws_iam_policy_document.allow_access_from_ec2_instance_profile.json
}

resource "aws_s3_bucket_public_access_block" "s3_automox_log_bucket_block" {
  bucket = aws_s3_bucket.s3_automox_log_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Creates SSM Association
# This runs runs the associated SSM document against SSM Managed instances on a schedule
resource "aws_ssm_association" "endpoint_tooling_compliance" {
  depends_on = [
    aws_ssm_document.install_automox_multi_os,
    aws_s3_bucket.s3_automox_log_bucket
  ]

  name = aws_ssm_document.install_automox_multi_os.name
  # Modify the Association name for your organization
  association_name = var.ssm_association_name
  # CRON Schedule, should be set to your desired schedule
  schedule_expression = var.cron_expression
  # Compliance Severity should be set to your tolerance
  compliance_severity = var.compliance_severity
  # Runs against all SSM Managed EC2 Instances, there is logic within the SSM Document to exit out if Automox is already installed.
  # There is not a way to exclude running against instances based on Tags, only include
  targets {
    key    = "InstanceIds"
    values = ["*"]
  }

  output_location {
    s3_bucket_name = var.aws_s3_automox_log_bucket
    s3_key_prefix  = "SSMInstallLogs/${var.account_id}/"
  }
}