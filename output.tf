output "route53_records_name" {
  value = var.route53_records_name
}

output "get_target_group_arn" {
  value = aws_lb_target_group.lb_target_group.arn
}