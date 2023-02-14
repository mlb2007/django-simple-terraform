resource "aws_key_pair" "production" {
  key_name   = "${var.ecs_cluster_name}_key_pair"
  public_key = file(var.ssh_pubkey_file)
}

##resource "aws_key_pair" "production" {
##  key_name   = "${var.ecs_cluster_name}_key_pair"
##  public_key = file(var.ssh_pubkey_file)
##}
#
#resource "tls_private_key" "ssh" {
#  algorithm = "RSA"
#  rsa_bits  = 4096
#}
#
#resource "aws_key_pair" "production" {
#  key_name   = "${var.ecs_cluster_name}_key_pair"
#  public_key = tls_private_key.ssh.public_key_openssh
#}
#
#output "ssh_private_key_pem" {
#  value = tls_private_key.ssh.private_key_pem
#  sensitive = true
#}
#
#output "ssh_public_key_pem" {
#  value = tls_private_key.ssh.public_key_pem
#}
#
