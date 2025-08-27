output "public_ip" { value = aws_instance.bastion.public_ip }
output "ssh_hint" {
  value = (length(var.ssh_public_key) > 0
    ? "ssh -i ~/.ssh/id_ed25519 ec2-user@${aws_instance.bastion.public_dns}"
    : "Use EC2 Instance Connect in the AWS console to connect")
}
