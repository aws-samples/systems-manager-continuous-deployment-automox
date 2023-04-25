output "sec_compliance_association" {
  description = "Association attributes."
  value       = aws_ssm_association.endpoint_tooling_compliance
  sensitive   = true
}