provider "aws" {
  region = "us-east-1"
}

resource "aws_ecs_cluster" "hello-world-cluster" {
  name = "hello-world-cluster"
}

resource "aws_ecs_task_definition" "hello-world-task" {
  family                = "hello-world-task"
  network_mode          = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                   = "256"
  memory                = "512"

  container_definitions = <<DEFINITION
  [
    {
      "name": "hello-world-container",
      "image": "your-dockerhub-username/hello-world-nodejs:latest",
      "cpu": 256,
      "memory": 512,
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000,
          "protocol": "tcp"
        }
      ]
    }
  ]
  DEFINITION
}

resource "aws_ecs_service" "hello-world-service" {
  name            = "hello-world-service"
  cluster         = aws_ecs_cluster.hello-world-cluster.id
  task_definition = aws_ecs_task_definition.hello-world-task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.main.id]
    security_groups = [aws_security_group.main.id]
    assign_public_ip = true
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_security_group" "main" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
