data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/handler.py"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/alarm-on-absence-ingest"
  retention_in_days = 30
}

resource "aws_lambda_function" "ingest" {
  function_name    = "alarm-on-absence-ingest"
  role             = aws_iam_role.lambda.arn
  handler          = "handler.handler"
  runtime          = "python3.13"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 15


  environment {
    variables = {
      DATA_BUCKET = aws_s3_bucket.s3_alarm_on_absence.id
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda]
}
