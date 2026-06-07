resource "random_password" "api_key" {
  length  = 32
  special = false
}

# --- Ingest Lambda ---

data "archive_file" "ingest" {
  type        = "zip"
  source_file = "${path.module}/lambda/ingest/handler.py"
  output_path = "${path.module}/lambda/ingest.zip"
}

resource "aws_iam_role" "ingest" {
  name = "garden-iot-ingest-lambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ingest" {
  role = aws_iam_role.ingest.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem"]
        Resource = aws_dynamodb_table.events.arn
      },
      {
        Effect   = "Allow"
        Action   = ["events:PutEvents"]
        Resource = aws_cloudwatch_event_bus.garden.arn
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_lambda_function" "ingest" {
  function_name    = "garden-iot-ingest"
  filename         = data.archive_file.ingest.output_path
  source_code_hash = data.archive_file.ingest.output_base64sha256
  handler          = "handler.handler"
  runtime          = "python3.12"
  role             = aws_iam_role.ingest.arn

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.events.name
      EVENT_BUS_NAME = aws_cloudwatch_event_bus.garden.name
    }
  }
}

# --- Query Lambda ---

data "archive_file" "query" {
  type        = "zip"
  source_file = "${path.module}/lambda/query/handler.py"
  output_path = "${path.module}/lambda/query.zip"
}

resource "aws_iam_role" "query" {
  name = "garden-iot-query-lambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "query" {
  role = aws_iam_role.query.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:Query"]
        Resource = aws_dynamodb_table.events.arn
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_lambda_function" "query" {
  function_name    = "garden-iot-query"
  filename         = data.archive_file.query.output_path
  source_code_hash = data.archive_file.query.output_base64sha256
  handler          = "handler.handler"
  runtime          = "python3.12"
  role             = aws_iam_role.query.arn

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.events.name
    }
  }
}

# --- Alert Lambda ---

data "archive_file" "alert" {
  type        = "zip"
  source_file = "${path.module}/lambda/alert/handler.py"
  output_path = "${path.module}/lambda/alert.zip"
}

resource "aws_iam_role" "alert" {
  name = "garden-iot-alert-lambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "alert" {
  role = aws_iam_role.alert.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ses:SendEmail"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_lambda_function" "alert" {
  function_name    = "garden-iot-alert"
  filename         = data.archive_file.alert.output_path
  source_code_hash = data.archive_file.alert.output_base64sha256
  handler          = "handler.handler"
  runtime          = "python3.12"
  role             = aws_iam_role.alert.arn

  environment {
    variables = {
      ALERT_EMAIL = var.alert_email
    }
  }
}
