output "cluster_name" {
  description = "value of the cluster name"
  value = aws_ecs_cluster.ecs_cluster.name
}

output "task_definition_arn" {
  description = "value of the task definition arn"
  value = aws_ecs_task_definition.task_definition.arn
}

output "service_name" {
  description = "value of the service name"
  value = aws_ecs_service.image_processing_service.name
}

output "lambda_function_name" {
  description = "value of the lambda function name"
  value = aws_lambda_function.image_processing.function_name
}

output "s3_bucket_name" {
  description = "value of the s3 bucket name"
  value = aws_s3_bucket.bucket_images.bucket
}