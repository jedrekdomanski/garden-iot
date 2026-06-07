# SES requires email verification before sending.
# After `terraform apply`, check your inbox and click the verification link.
resource "aws_ses_email_identity" "alert" {
  email = var.alert_email
}
