locals {
    app = templatefile("templates/django_app.json.tftpl", {
    docker_image_url_django = var.docker_image_url_django
    region                  = var.region
  })
  user_data = templatefile("templates/user_data.tftpl", {
      ecs_cluster_name = var.ecs_cluster_name
  })
}

resource "aws_ecs_cluster" "production" {
  name = "${var.ecs_cluster_name}-cluster"
}

resource "aws_launch_template" "ecs" {
  #name_prefix = "${var.ecs_cluster_name}-cluster"
  name = "${var.ecs_cluster_name}-cluster"
  
  disable_api_termination = true
  
  iam_instance_profile {
    name = aws_iam_instance_profile.ecs.name
  }
  
  image_id = lookup(var.amis, var.region)
  
  instance_initiated_shutdown_behavior = "terminate"
  
  instance_type = var.instance_type
  
  key_name = aws_key_pair.production.key_name
  
  vpc_security_group_ids = [aws_security_group.ecs.id]
  
  user_data = "${base64encode(local.user_data)}"
  
  lifecycle {
    create_before_destroy = true
  }
}


# old: container_definitions = data.template_file.app.rendered
resource "aws_ecs_task_definition" "app" {
  family                = "django-app"
  
  container_definitions =  local.app

}


resource "aws_ecs_service" "production" {
  name            = "${var.ecs_cluster_name}-service"
  cluster         = aws_ecs_cluster.production.id
  task_definition = aws_ecs_task_definition.app.arn
  iam_role        = aws_iam_role.ecs-service-role.arn
  desired_count   = var.app_count
  
  depends_on      = [aws_alb_listener.ecs-alb-http-listener, aws_iam_role_policy.ecs-service-role-policy]

  load_balancer {
    target_group_arn = aws_alb_target_group.default-target-group.arn
    container_name   = "django-app"
    container_port   = 8000
  }
}

