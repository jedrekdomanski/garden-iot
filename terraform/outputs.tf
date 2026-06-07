output "api_endpoint" {
  description = "HTTPS endpoint for the ESP32 to POST events to"
  value       = "${aws_apigatewayv2_api.garden.api_endpoint}/events"
}

output "api_key" {
  description = "API key for ESP32 authentication — store in NVS flash, not in firmware"
  value       = random_password.api_key.result
  sensitive   = true
}

output "grafana_access_key_id" {
  description = "AWS access key ID for Grafana Cloud"
  value       = aws_iam_access_key.grafana.id
}

output "grafana_secret_access_key" {
  description = "AWS secret access key for Grafana Cloud"
  value       = aws_iam_access_key.grafana.secret
  sensitive   = true
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.events.name
}
