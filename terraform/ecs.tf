resource "aws_ecs_cluster" "aws-ecs-cluster" {
  name = "${var.app_name}-${var.environment}-cluster"
  tags = {
    Name        = "${var.app_name}-ecs"
    Environment = var.environment
  }
}

resource "aws_ecr_repository" "bars_container_registry" {
  name = "${var.app_name}-${var.environment}-ecr"
  tags = {
    Name        = "${var.app_name}-ecr"
    Environment = var.environment
  }
}
resource "aws_cloudwatch_log_group" "log-group" {
  name = "${var.app_name}-${var.environment}-logs"

  tags = {
    Application = var.app_name
    Environment = var.environment
  }
}

#      "image": "${aws_ecr_repository.bars_container_registry.repository_url}:latest",
resource "aws_ecs_task_definition" "aws-ecs-task" {
  family = "${var.app_name}-task"

  container_definitions = jsonencode([
    {
      name: "${var.app_name}-${var.environment}-container",
      image     = "vad1mo/hello-world-rest"
      cpu       = 256
      memory    = 512
      essential = true
      logConfiguration: {
        logDriver: "awslogs",
        options: {
          awslogs-group: aws_cloudwatch_log_group.log-group.id,
          awslogs-region: var.region,
          awslogs-stream-prefix: "${var.app_name}-${var.environment}"
        }
      },
      portMappings = [
        {
          containerPort = 5050
          hostPort      = 5050
        }
      ]
    }
  ])

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = "512"
  cpu                      = "256"
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecsTaskExecutionRole.arn

  tags = {
    Name        = "${var.app_name}-ecs-td"
    Environment = var.environment
  }
}

data "aws_ecs_task_definition" "main" {
  task_definition = aws_ecs_task_definition.aws-ecs-task.family
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "${var.app_name}-execution-task-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags = {
    Name        = "${var.app_name}-iam-role"
    Environment = var.environment
  }
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
resource "aws_ecs_service" "aws-ecs-service" {
  name                 = "${var.app_name}-${var.environment}-ecs-service"
  cluster              = aws_ecs_cluster.aws-ecs-cluster.id
  task_definition      = "${aws_ecs_task_definition.aws-ecs-task.family}:${max(aws_ecs_task_definition.aws-ecs-task.revision, data.aws_ecs_task_definition.main.revision)}"
  launch_type          = "FARGATE"
  scheduling_strategy  = "REPLICA"
  desired_count        = 1
  force_new_deployment = true

  network_configuration {
    subnets          = aws_subnet.private_subnets.*.id
    assign_public_ip = false
    security_groups = [
      aws_security_group.service_security_group.id,
      aws_security_group.load_balancer_security_group.id
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = "${var.app_name}-${var.environment}-container"
    container_port   = 5050
  }

  depends_on = [aws_lb_listener.listener]
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}
