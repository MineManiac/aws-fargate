resource "aws_lambda_function" "image_processing" {
  function_name    = "image-processing"
  role             = aws_iam_role.lambda_role.arn
  handler          = "hello-world.handler"
  runtime          = "nodejs14.x"
  filename         = "hello-world.zip"
  source_code_hash = filebase64sha256("hello-world.zip")

  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.bucket_images.bucket
    }
  }
}