# The name of ECR resource should all be lower letters, otherwise u will get
# errors
#
resource "aws_ecr_repository" "django-app" {
  name  = "${var.project_name}_ec2"
  image_tag_mutability = "MUTABLE"
}

