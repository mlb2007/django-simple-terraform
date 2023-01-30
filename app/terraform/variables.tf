# core
variable "region" {
  description = "The AWS region to create resources in."
  default     = "us-west-2"
}

# networking
variable "public_subnet_1_cidr" {
  description = "CIDR Block for Public Subnet 1"
  default     = "10.0.1.0/24"
}
variable "public_subnet_2_cidr" {
  description = "CIDR Block for Public Subnet 2"
  default     = "10.0.2.0/24"
}
variable "private_subnet_1_cidr" {
  description = "CIDR Block for Private Subnet 1"
  default     = "10.0.3.0/24"
}
variable "private_subnet_2_cidr" {
  description = "CIDR Block for Private Subnet 2"
  default     = "10.0.4.0/24"
}
variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-west-2b", "us-west-2c"]
}

# load balancer

variable "health_check_path" {
  description = "Health check path for the default target group"
  default     = "/ping/"
}


# ecs

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  default     = "production"
}

# logs

variable "log_retention_in_days" {
  default = 30
}

# key pair

variable "ssh_pubkey_file" {
  description = "Path to an SSH public key"
  default     = "~/.ssh/id_rsa.pub"
}

# ecs

# with docker installed, got info by executing:
# aws ssm get-parameters --names /aws/service/ecs/optimized-ami/amazon-linux-2/recommended --region us-west-2
# ami I found 
# us-west-2 = "ami-014cdb1bfb3b2584f"
# the following is as given in the web page and does not work
# us-west-2 = "ami-0bd3976c0dbacc605"

variable "amis" {
  description = "Which AMI to spawn."
  default = {
    us-west-2 = "ami-06e85d4c3149db26a"
  }
}
variable "instance_type" {
  default = "t2.micro"
}
variable "docker_image_url_django" {
  description = "Docker image to run in the ECS cluster"
  default = "072507290151.dkr.ecr.us-west-2.amazonaws.com/django-app_ec2:latest" 
}

variable "app_count" {
  description = "Number of Docker containers to run"
  default     = 1
}

# auto scaling

variable "autoscale_min" {
  description = "Minimum autoscale (number of EC2)"
  default     = "1"
}
variable "autoscale_max" {
  description = "Maximum autoscale (number of EC2)"
  default     = "10"
}
variable "autoscale_desired" {
  description = "Desired autoscale (number of EC2)"
  default     = "4"
}

variable "bucket_name" {
  default = "terraform-access-log-bucket-django-app"
}

