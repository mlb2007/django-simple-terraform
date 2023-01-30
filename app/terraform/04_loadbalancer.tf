## Production Load Balancer
resource "aws_alb" "production" {
  name               = "${var.ecs_cluster_name}-alb"
  security_groups    = [aws_security_group.load-balancer.id]
  subnets            = [aws_subnet.public-subnet-1.id, aws_subnet.public-subnet-2.id]
  access_logs {
    bucket  = "${aws_s3_bucket.s3-bucket.bucket}"
    prefix  = "my-http-alb"
    enabled = true
  }
}


# Target group
resource "aws_alb_target_group" "default-target-group" {
  name     = "${var.ecs_cluster_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.production-vpc.id
  target_type = "instance"
  
  health_check {
    path = var.health_check_path
    port = "traffic-port"
    matcher = "200"
    protocol = "HTTP"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 2
    interval            = 5  
  }
}

# Listener (redirects traffic from the load balancer to the target group)
resource "aws_alb_listener" "ecs-alb-http-listener" {
  load_balancer_arn = aws_alb.production.id
  port              = 80
  protocol          = "HTTP"
  depends_on        = [aws_alb_target_group.default-target-group]

  default_action {
    type = "forward"
    target_group_arn = aws_alb_target_group.default-target-group.arn
  } 
  
  #default_action {
  #  type = "fixed-response"
  #  fixed_response {
  #    content_type = "text/plain"
  #    message_body = "HEALTHY"
  #    status_code  = "200"
  #  }
  #}

}

resource "aws_alb_listener_rule" "ecs-alb-http-listener-rule" {
  listener_arn = aws_alb_listener.ecs-alb-http-listener.arn
  priority  = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type = "forward"
    target_group_arn = aws_alb_target_group.default-target-group.arn
  }

  depends_on = [aws_alb_target_group.default-target-group]

}

resource "aws_s3_bucket" "s3-bucket" {
  bucket = "${var.bucket_name}"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "s3_bucket_acl" {
  bucket = aws_s3_bucket.s3-bucket.id
  acl    = "public-read"
}


resource "aws_s3_bucket_policy" "s3-bucket-policy" {
  bucket = aws_s3_bucket.s3-bucket.id
  policy = data.aws_iam_policy_document.s3_bucket_lb_write.json
}


data "aws_iam_policy_document" "s3_bucket_lb_write" {
  policy_id = "s3_bucket_lb_logs"

  statement {
    actions = [
      "s3:PutObject",
    ]
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.s3-bucket.arn}/*",
    ]

    principals {
      # the number is for us-west-2
      identifiers = ["arn:aws:iam::797873946194:root"]
      type        = "AWS"
    }
  }

  statement {
    actions = [
      "s3:PutObject"
    ]
    effect = "Allow"
    resources = ["${aws_s3_bucket.s3-bucket.arn}/*"]
    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
  }


  statement {
    actions = [
      "s3:GetBucketAcl"
    ]
    effect = "Allow"
    resources = ["${aws_s3_bucket.s3-bucket.arn}"]
    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
  }
}

output "bucket_name" {
  value = "${aws_s3_bucket.s3-bucket.bucket}"
}


