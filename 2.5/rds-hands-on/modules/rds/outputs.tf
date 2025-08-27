output "endpoint" { value = aws_db_instance.db.address }
output "port" { value = aws_db_instance.db.port }
output "master_secret_arn" { value = try(aws_db_instance.db.master_user_secret[0].secret_arn, null) }
