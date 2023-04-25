variable "account_id" {
  type        = string
  description = "Enter the account number that you wish to deploy in."
}

variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "Enter the AWS Region you wish to deploy in."
  validation {
    condition     = can(regex("(us(-gov)?|ap|ca|cn|eu|sa)-(central|(north|south)?(east|west)?)-\\d", var.aws_region))
    error_message = "Enter a valid region."
  }
}

variable "automox_apikey" {
  type        = string
  description = "Enter the Automox API Key."
  sensitive   = true
}

variable "aws_s3_automox_log_bucket" {
  type        = string
  description = "Enter the name for the S3 bucket which will store Automox installation output."
  validation {
    condition     = substr(var.aws_s3_automox_log_bucket, 0, 1) != "/" && substr(var.aws_s3_automox_log_bucket, -1, 1) != "/" && length(var.aws_s3_automox_log_bucket) > 0
    error_message = "Parameter `aws_s3_automox_log_bucket` cannot start and end with \"/\", as well as cannot be empty."
  }
}

variable "ssm_association_name" {
  type        = string
  description = "Enter the name for the System's Manager continuous check."
}

variable "compliance_severity" {
  type        = string
  description = "Enter the severity level for when Automox is not installed."
  validation {
    condition     = contains(["CRITICAL","HIGH","MEDIUM","LOW","UNSPECIFIED"], var.compliance_severity)
    error_message = "Invalid input, options are: \"CRITICAL\", \"HIGH\",\"MEDIUM\",\"LOW\", and \"UNSPECIFIED\"."
  }
}

variable "cron_expression" {
  type        = string
  description = "Enter the CRON expression to schedule the association check."
}

variable "aws_ec2_instance_profile" {
  type        = string
  description = "Enter the name for the instance profile attached to EC2 instances which should be granted access to write to the Automox Logging S3 bucket. This role must already exist."
}