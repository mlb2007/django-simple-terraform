output "alb_hostname" {
  value = aws_alb.production.dns_name
}

