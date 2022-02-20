resource "aws_lambda_permission" "allow_stage_bucket" {
  function_name = aws_lambda_function.adobe_post_data_processor.arn
  action        = "lambda:InvokeFunction"
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.app_outbound.arn
}

data "archive_file" "init_postprocess" {
  type        = "zip"
  source_dir  = "Lambda_postprocess"
  output_path = "outputs/deployment_posts.zip"
}

resource "aws_lambda_function" "adobe_post_data_processor" {
  function_name = "adobe_post_data_processor"
  role          = "arn:aws:iam::143114426560:role/service-role/test-role-fd1arkpr"
  memory_size   = 1024
  timeout       = 300
  environment {
    variables = {
      emr_cluster_id   = "j-1P779IL7I2AH0"
      output_bucket    = "logs-adobe-outbound"
      output_prefix    = "data/postprocess"
    }
  }
  handler       = "main.lambda_handler"
  runtime       = "python3.7"
  filename      = "outputs/deployment_posts.zip"
}

resource "aws_s3_bucket_notification" "stage_bucket_notification" {
  bucket   = aws_s3_bucket.app_outbound.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.adobe_post_data_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "data/raw"
  }

  depends_on = [aws_lambda_permission.allow_stage_bucket]
}
