data "template_file" "todo-app" {
  template = file("${path.module}/templates/svc-template.tpl")
  vars = {
    LOG_GROUP_NAME = var.ecs_log_group
    REGISTRY_REPO  = aws_ecr_repository.task-app-repo.repository_url
    CONTAINER_NAME = "todo-app"
    AWS_REGION     = var.aws_region
    REGISTRY_IMAGE = "${var.task_app_server_image}:${var.task_app_server_version}"
  }
}

resource "aws_ecs_task_definition" "todo-app" {
  family                   = "todo-app-container"
  container_definitions    = data.template_file.todo-app.rendered
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  task_role_arn            = aws_iam_role.ecs_api_container_assume.arn
  execution_role_arn       = aws_iam_role.ecs_api_task_assume.arn

  lifecycle {
    create_before_destroy = "true"
  }

  tags = merge(
    map(
      "Name", "Fargate"
    )
  )
}

resource "aws_ecs_service" "todo-app" {
  name            = "todo-app-service"
  cluster         = aws_ecs_cluster.ecs-cluster.id
  task_definition = aws_ecs_task_definition.todo-app.arn
  desired_count   = "1"
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [var.aws_security_group_ecs_api]
    subnets         = aws_subnet.private_subnet
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api_lb_target_group.arn
    container_name   = "todo-app"
    container_port   = 3000
  }

  lifecycle {
    create_before_destroy = "true"
  }
}
