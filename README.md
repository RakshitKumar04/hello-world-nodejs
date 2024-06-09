# Hello World Node.js App Deployment with Terraform, AWS ECS/Fargate, and GitHub Actions

This project demonstrates how to design Infrastructure as Code (IaC) using Terraform, deploy a "Hello World" Node.js application on AWS ECS/Fargate, and set up a Continuous Deployment (CD) pipeline using GitHub Actions.

## Table of Contents

1. [Architecture](#architecture)
2. [Prerequisites](#prerequisites)
3. [Project Setup](#project-setup)
4. [Terraform Configuration](#terraform-configuration)
5. [Node.js Application](#nodejs-application)
6. [GitHub Actions CI/CD Pipeline](#github-actions-cicd-pipeline)
7. [Screenshots](#screenshots)
8. [Screencast](#screencast)
9. [Conclusion](#conclusion)

## Architecture

The project architecture includes the following components:

- **Node.js Application**: A simple "Hello World" app.
- **Docker**: Containerizes the Node.js app.
- **AWS ECS/Fargate**: Runs the Docker container.
- **Terraform**: Manages the infrastructure on AWS.
- **GitHub Actions**: Automates the CI/CD pipeline.

![image](https://github.com/RakshitKumar04/hello-world-nodejs/assets/72027411/94585ce8-8ab9-477e-8c9c-78c7fddb2a1c)

## Prerequisites

Before you begin, ensure you have the following installed:

- [Node.js](https://nodejs.org/)
- [Docker](https://www.docker.com/)
- [Terraform](https://www.terraform.io/)
- [AWS CLI](https://aws.amazon.com/cli/)
- [GitHub CLI](https://cli.github.com/)

## Project Setup

1. **Clone the Repository**

    ```sh
    git clone git@github.com:RakshitKumar04/hello-world-nodejs.git
    ```

2. **Set Up AWS CLI**

    Configure AWS CLI with your credentials.

    ```sh
    aws configure
    ```

3. **Set Up Docker**
   
    [Docker Repo](https://hub.docker.com/repository/docker/kumarrakshit0402/hello-world-nodejs/general)
   
    Log in to Docker Hub.

    ```sh
    docker login 
    ```

## Terraform Configuration

1. **Create Terraform Directory**

    ```sh
    mkdir terraform
    cd terraform
    ```

2. **Create `main.tf`**

    ```hcl
    provider "aws" {
      region = "us-east-1"
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

    resource "aws_ecs_cluster" "hello-world-cluster" {
      name = "hello-world-cluster"
    }

    resource "aws_ecs_task_definition" "hello-world-task" {
      family                   = "hello-world-task"
      network_mode             = "awsvpc"
      requires_compatibilities = ["FARGATE"]
      cpu                      = "256"
      memory                   = "512"

      container_definitions = <<DEFINITION
      [
        {
          "name": "hello-world-container",
          "image": "kumarrakshit0402/hello-world-nodejs:latest",
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
        subnets          = [aws_subnet.main.id]
        security_groups  = [aws_security_group.main.id]
        assign_public_ip = true
      }
    }
    ```

3. **Initialize Terraform**

    ```sh
    terraform init
    ```

4. **Apply Terraform Configuration**

    ```sh
    terraform apply
    ```

## Node.js Application

1. **Create Node.js Application**

    ```sh
    mkdir hello-world-nodejs
    cd hello-world-nodejs
    ```

2. **Create `package.json`**

    ```json
    {
      "name": "hello-world-nodejs",
      "version": "1.0.0",
      "main": "index.js",
      "dependencies": {
        "express": "^4.17.1"
      },
      "scripts": {
        "start": "node index.js"
      }
    }
    ```

3. **Create `index.js`**

    ```js
    const express = require('express');
    const app = express();
    const port = 3000;

    app.get('/', (req, res) => {
      res.send('Hello, World!');
    });

    app.listen(port, () => {
      console.log(`Example app listening at http://localhost:${port}`);
    });
    ```

4. **Create `Dockerfile`**

    ```Dockerfile
    FROM node:14-alpine
    WORKDIR /app
    COPY package*.json ./
    RUN npm install
    COPY . .
    EXPOSE 3000
    CMD [ "node", "index.js" ]
    ```

5. **Build and Push Docker Image**

    ```sh
    docker build -t kumarrakshit0402/hello-world-nodejs:latest .
    docker push kumarrakshit0402/hello-world-nodejs:latest
    ```

## GitHub Actions CI/CD Pipeline

1. **Create GitHub Actions Workflow File**

    ```yaml
    name: CI/CD pipeline

    on:
      push:
        branches:
          - main

    jobs:
      deploy:
        runs-on: ubuntu-latest

        steps:
          - name: Checkout code
            uses: actions/checkout@v2

          - name: Set up Docker
            uses: docker/setup-buildx-action@v1

          - name: Build Docker image
            run: docker build -t kumarrakshit0402/hello-world-nodejs:latest .

          - name: Login to Docker Hub
            run: echo "${{ secrets.DOCKER_HUB_PASSWORD }}" | docker login -u "${{ secrets.DOCKER_HUB_USERNAME }}" --password-stdin

          - name: Push Docker image to Docker Hub
            run: docker push kumarrakshit0402/hello-world-nodejs:latest

          - name: Set AWS Region
            run: echo "AWS_REGION=us-east-1" >> $GITHUB_ENV

          - name: Deploy to ECS
            uses: aws-actions/amazon-ecs-deploy-task-definition@v1
            with:
              task-definition: task-definition.json
              service: hello-world-service
              cluster: hello-world-cluster
              wait-for-service-stability: true
    ```

2. **Add Secrets to GitHub Repository**

    - `DOCKER_HUB_USERNAME`: Your Docker Hub username.
    - `DOCKER_HUB_PASSWORD`: Your Docker Hub password.
    - `AWS_ACCESS_KEY_ID`: Your AWS access key ID.
    - `AWS_SECRET_ACCESS_KEY`: Your AWS secret access key.

## Screenshots

Include relevant screenshots of your project setup, Terraform execution, Docker image build and push, and GitHub Actions workflow run.

![Terraform Init](https://github.com/RakshitKumar04/hello-world-nodejs/assets/72027411/71eb1122-7b90-4e22-a3e5-47b42c875f76)

![Docker Build](https://github.com/RakshitKumar04/hello-world-nodejs/assets/72027411/d7f85bb1-a374-480e-bcdf-d40858bdf1bc)

![GitHub action](https://github.com/RakshitKumar04/hello-world-nodejs/assets/72027411/d88a882e-9a21-4f0b-9b9a-3b537d200b4a)


## Screencast

Link to a screencast demonstrating the entire process.

[Screencast Link](path-to-screencast.mp4)

## Conclusion

This project demonstrates the end-to-end process of deploying a Node.js application using Terraform, AWS ECS/Fargate, and GitHub Actions. By following the steps outlined, you can set up a similar infrastructure and CI/CD pipeline for your own applications.


Happy coding!
