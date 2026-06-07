# Dedicated IAM user for Grafana Cloud with minimal DynamoDB read-only permissions
resource "aws_iam_user" "grafana" {
  name = var.grafana_iam_user_name
}

resource "aws_iam_access_key" "grafana" {
  user = aws_iam_user.grafana.name
}

resource "aws_iam_user_policy" "grafana" {
  user = aws_iam_user.grafana.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:GetItem",
          "dynamodb:DescribeTable",
        ]
        Resource = aws_dynamodb_table.events.arn
      }
    ]
  })
}
