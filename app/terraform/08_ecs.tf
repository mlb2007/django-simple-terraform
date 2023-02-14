# User data has info about setting nginx webserver and reverse proxy
# Ref: https://mattsegal.dev/nginx-django-reverse-proxy-config.html
# Ref: https://www.digitalocean.com/community/tutorials/how-to-set-up-django-with-postgres-nginx-and-gunicorn-on-ubuntu-16-04
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

resource "aws_launch_configuration" "ecs" {
  name_prefix                 = "ec2-${var.ecs_cluster_name}-"
  image_id                    = lookup(var.amis, var.region)
  instance_type               = var.instance_type
  security_groups             = [aws_security_group.load-balancer.id, aws_security_group.ecs.id]
  iam_instance_profile        = aws_iam_instance_profile.ecs.name
  key_name                    = aws_key_pair.production.key_name
  user_data_base64 = "${base64encode(local.user_data)}"
  associate_public_ip_address = "true"
  
  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_ecs_task_definition" "app" {
  family                = "django-app"
  container_definitions =  local.app    
  
  # required for calling APIs on behalf of ECS instance
  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  
  # required to run the container task, in this case, the Django task
  task_role_arn      = aws_iam_role.ecs-service-role.arn

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



##### -============
#locals {
#    app = templatefile("templates/django_app.json.tftpl", {
#    docker_image_url_django = var.docker_image_url_django
#    region                  = var.region
#  })
#  user_data = templatefile("templates/user_data.tftpl", {
#      ecs_cluster_name = var.ecs_cluster_name
#  })
#}
#
#resource "aws_ecs_cluster" "production" {
#  name = "${var.ecs_cluster_name}-cluster"
#}
#
#### EC2 role ###
#data "aws_iam_policy_document" "ecs_agent" {
#  statement {
#    actions = ["sts:AssumeRole"]
#
#    principals {
#      type        = "Service"
#      identifiers = ["ec2.amazonaws.com"]
#    }
#  }
#}
#
#resource "aws_iam_role" "ecs_agent" {
#  name               = "ecs-agent"
#  assume_role_policy = data.aws_iam_policy_document.ecs_agent.json
#}
#
#
#resource "aws_iam_role_policy_attachment" "ecs_agent" {
#  role       = aws_iam_role.ecs_agent.name
#  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
#}
#
#resource "aws_iam_instance_profile" "ecs_agent" {
#  name = "ecs-agent"
#  role = aws_iam_role.ecs_agent.name
#}
#
#
#resource "aws_launch_template" "ecs" {
#  name_prefix = "${var.ecs_cluster_name}-cluster"
#  #name = "${var.ecs_cluster_name}-cluster"
#  
#  disable_api_termination = true
#  
#  iam_instance_profile {
#    #name = aws_iam_instance_profile.ecs.name
#    arn = aws_iam_instance_profile.ecs_agent.arn
#  }
#  
#  #image_id = lookup(var.amis, var.region)
#  image_id = var.amis
#  
#  instance_initiated_shutdown_behavior = "terminate"
#  
#  instance_type = var.instance_type
#  
#  key_name = aws_key_pair.production.key_name
#  
#  vpc_security_group_ids = [aws_security_group.ecs.id]
#  
#  user_data = "${base64encode(local.user_data)}"
#  
#  lifecycle {
#    create_before_destroy = true
#  }
#
#  #metadata_options {
#  #  http_endpoint               = "enabled"
#  #  http_tokens                 = "required"
#  #  http_put_response_hop_limit = 1
#  #  instance_metadata_tags      = "enabled"
#  #}
#
#  monitoring {
#    enabled = true
#  }
#
#  #network_interfaces {
#  #  associate_public_ip_address = true
#  #}
#
#}
#
#########
## IAM roles and policies
#resource "aws_iam_role" "prod_backend_task" {
#  name = "prod-backend-task"
#
#  # who can assume this role ? (trust policy)
#  assume_role_policy = jsonencode({
#    Version = "2012-10-17",
#    Statement = [
#      {
#        Action = "sts:AssumeRole",
#        Principal = {
#          Service = "ecs-tasks.amazonaws.com"
#        },
#        Effect = "Allow",
#        Sid    = ""
#      }
#    ]
#  })
#  
#  ## permission policy
#  ## instead of making policy and attaching to this role
#  ## we make the policy inline
#  #inline_policy {
#  #  name = "prod-backend-task-ssmmessages"
#  #  policy = jsonencode({
#  #    Version = "2012-10-17"
#  #    Statement = [
#  #      {
#  #        Action   = [
#  #          "ssmmessages:CreateControlChannel",
#  #          "ssmmessages:CreateDataChannel",
#  #          "ssmmessages:OpenControlChannel",
#  #          "ssmmessages:OpenDataChannel",
#  #        ]
#  #        Effect   = "Allow"
#  #        Resource = "*"
#  #      },
#  #    ]
#  #  })
#  #}
#}

resource "aws_iam_role" "ecs_task_execution" {
  name = "ecs-task-execution"

  # who do u trust for this iam role ? (trust policy)
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Action = "sts:AssumeRole",
          Principal = {
            Service = "ecs-tasks.amazonaws.com"
          },
          Effect = "Allow",
          Sid    = ""
        }
      ]
    }
  )
}

# Now the IAM role must have some policy. In this case it simply copies
# the policy that allows ECS tasks to be executed in this role ...
resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution.name
  
  # permissions policy, attached to roles, a default Task Execution Policy is
  # used
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"

}


########
#
#
#
## old: container_definitions = data.template_file.app.rendered
#resource "aws_ecs_task_definition" "app" {
#  family                = "django-app"
#  container_definitions =  local.app
#  
#  #network_mode = "awsvpc"
#  
#  # required for calling APIs on behalf of ECS instance
#  execution_role_arn = aws_iam_role.ecs_task_execution.arn
#  
#  # required to run the container task, in this case, the Django task
#  task_role_arn      = aws_iam_role.prod_backend_task.arn
#}
#
#
#resource "aws_ecs_service" "production" {
#  name            = "${var.ecs_cluster_name}-service"
#  cluster         = aws_ecs_cluster.production.id
#  task_definition = aws_ecs_task_definition.app.arn
#  iam_role        = aws_iam_role.ecs-service-role.arn
#  desired_count   = var.app_count
#  
#  depends_on      = [aws_alb_listener.ecs-alb-http-listener, aws_iam_role_policy.ecs-service-role-policy]
#
#  load_balancer {
#    target_group_arn = aws_alb_target_group.default-target-group.arn
#    container_name   = "django-app"
#    container_port   = 8000
#  }
#
#  ## All my instances spawned need to be in private subnet
#  #network_configuration {
#  #  security_groups  = [aws_security_group.prod_ecs_backend.id]
#  #  subnets  = [aws_subnet.private-subnet-1.id, aws_subnet.private-subnet-2.id]
#  #  assign_public_ip = false
#  #}
#}
#
## Security Group
## the backend, the ECS service belong to the security group
## of ALB and so can only interact with it and no-one else
##
#resource "aws_security_group" "prod_ecs_backend" {
#  name        = "prod-ecs-backend"
#  vpc_id   = aws_vpc.production-vpc.id
#
#  ingress {
#    from_port       = 0
#    to_port         = 0
#    protocol        = "-1"
#    security_groups = [aws_security_group.load-balancer.id]
#  }
#
#  egress {
#    from_port   = 0
#    to_port     = 0
#    protocol    = "-1"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#}




