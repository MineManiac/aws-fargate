# Configure the AWS Provider
provider "aws" {
  region = "us-east-2"
  alias  = "us-east-2"
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ecs-cluster"
}

data "local_file" "containerdefinitions" {
  filename = "containerdefinitions.json"
}

resource "aws_ecs_task_definition" "task_definition" {
  family                   = "image-processor"
  execution_role_arn       = aws_iam_role.ecs_role.arn
  task_role_arn            = aws_iam_role.task_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  memory =  512
  cpu = 256

  container_definitions = data.local_file.containerdefinitions.content

}

resource "aws_ecs_service" "image_processing_service" {
  name            = "image_processing_service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = 1

  network_configuration {
    subnets = [aws_subnet.subnet.id]
  }
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true
}

