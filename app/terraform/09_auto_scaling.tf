resource "aws_autoscaling_group" "ecs-cluster" {
  name                 = "${var.ecs_cluster_name}_auto_scaling_group"
  min_size             = var.autoscale_min
  max_size             = var.autoscale_max
  desired_capacity     = var.autoscale_desired
  health_check_type    = "EC2"
 
  target_group_arns    = [aws_alb_target_group.default-target-group.arn]

  # used to place EC2 instances spwaned  
  vpc_zone_identifier  = [aws_subnet.private-subnet-1.id, aws_subnet.private-subnet-2.id]

  lifecycle {
    create_before_destroy = true
  }

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }   
 
  depends_on = [aws_launch_template.ecs]

}



