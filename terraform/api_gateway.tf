resource "aws_apigatewayv2_api" "garden" {
  name          = "garden-iot"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_authorizer" "api_key" {
  api_id                            = aws_apigatewayv2_api.garden.id
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = aws_lambda_function.authorizer.invoke_arn
  identity_sources                  = ["$request.header.x-api-key"]
  name                              = "api-key-authorizer"
  authorizer_payload_format_version = "2.0"
  enable_simple_responses           = true
}

resource "aws_apigatewayv2_integration" "ingest" {
  api_id                 = aws_apigatewayv2_api.garden.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.ingest.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "post_events" {
  api_id             = aws_apigatewayv2_api.garden.id
  route_key          = "POST /events"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.api_key.id
  target             = "integrations/${aws_apigatewayv2_integration.ingest.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.garden.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "query" {
  api_id                 = aws_apigatewayv2_api.garden.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.query.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_metrics" {
  api_id             = aws_apigatewayv2_api.garden.id
  route_key          = "GET /metrics"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.api_key.id
  target             = "integrations/${aws_apigatewayv2_integration.query.id}"
}

resource "aws_lambda_permission" "apigw_query" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.query.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.garden.execution_arn}/*/*"
}

# Lambda permission for API Gateway to invoke ingest
resource "aws_lambda_permission" "apigw_ingest" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingest.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.garden.execution_arn}/*/*"
}

# Lambda permission for API Gateway to invoke authorizer
resource "aws_lambda_permission" "apigw_authorizer" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.garden.execution_arn}/*/*"
}

# --- API Key Authorizer Lambda ---

data "archive_file" "authorizer" {
  type        = "zip"
  source_file = "${path.module}/lambda/authorizer/handler.py"
  output_path = "${path.module}/lambda/authorizer.zip"
}

resource "aws_iam_role" "authorizer" {
  name = "garden-iot-authorizer-lambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "authorizer_logs" {
  role       = aws_iam_role.authorizer.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "authorizer" {
  function_name    = "garden-iot-authorizer"
  filename         = data.archive_file.authorizer.output_path
  source_code_hash = data.archive_file.authorizer.output_base64sha256
  handler          = "handler.handler"
  runtime          = "python3.12"
  role             = aws_iam_role.authorizer.arn

  environment {
    variables = {
      API_KEY = random_password.api_key.result
    }
  }
}
