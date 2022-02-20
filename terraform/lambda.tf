resource "aws_lambda_permission" "allow_bucket" {
  function_name = aws_lambda_function.adobe_data_processor.arn
  action        = "lambda:InvokeFunction"
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.app_inbound.arn
}

data "archive_file" "init" {
  type        = "zip"
  source_dir  = "Lambda"
  output_path = "outputs/deployment_pres.zip"
}

resource "aws_lambda_function" "adobe_data_processor" {
  function_name = "adobe_data_processor"
  role          = "arn:aws:iam::143114426560:role/service-role/test-role-fd1arkpr"
  memory_size   = 256
  timeout       = 300
  environment {
    variables = {
      emr_cluster_id   = "j-3364PO6XRC81A"
      output_path      = "s3://logs-adobe-outbound/data/raw"
      executor_memory  = "1G"
      driver_memory    = "2G"
      job_name         = "job_transform"
      code_artifacts   = "s3://adobe-code-artifacts"
      jar_file         = "s3://us-east-1.elasticmapreduce/libs/script-runner/script-runner.jar"
    }
  }
  handler       = "main.lambda_handler"
  runtime       = "python3.7"
  filename      = "outputs/deployment_pres.zip"
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket   = aws_s3_bucket.app_inbound.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.adobe_data_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "data/"
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

