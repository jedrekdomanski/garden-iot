resource "aws_dynamodb_table" "events" {
  name         = "garden-iot-events"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "device_id"
  range_key    = "ingested_at"

  attribute {
    name = "device_id"
    type = "S"
  }

  attribute {
    name = "ingested_at"
    type = "S"
  }

  # Keep data for 1 year, then auto-expire
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }
}
