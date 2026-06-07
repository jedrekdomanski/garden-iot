variable "alert_email" {
  description = "Email address to receive irrigation alerts"
  type        = string
}

variable "grafana_iam_user_name" {
  description = "IAM user name for Grafana Cloud to query DynamoDB"
  type        = string
  default     = "grafana-garden-iot"
}
