resource "aws_cloudwatch_event_bus" "garden" {
  name = "garden-iot"
}

resource "aws_cloudwatch_event_rule" "alert" {
  name           = "garden-iot-alert"
  event_bus_name = aws_cloudwatch_event_bus.garden.name

  event_pattern = jsonencode({
    source      = ["garden.iot"]
    detail-type = ["measurement_taken"]
    detail = {
      moisture_percent = [{ numeric = ["<", 30] }]
    }
  })
}

resource "aws_cloudwatch_event_target" "alert_lambda" {
  rule           = aws_cloudwatch_event_rule.alert.name
  event_bus_name = aws_cloudwatch_event_bus.garden.name
  target_id      = "alert-lambda"
  arn            = aws_lambda_function.alert.arn
}

resource "aws_lambda_permission" "eventbridge_alert" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alert.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.alert.arn
}
