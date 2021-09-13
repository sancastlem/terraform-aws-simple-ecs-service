## Task definition
data "template_file" "container_definition" {
  template = var.container_definition_template
  vars     = var.container_definition_vars
}

resource "aws_ecs_task_definition" "ecs_service_task_definition" {
  family                = "${var.name}_task_def"
  container_definitions = data.template_file.container_definition.rendered
  execution_role_arn    = var.execution_role_arn != "" ? var.execution_role_arn : null
  
  dynamic "volume" {
    for_each = var.volume 
    content {
      name      = volume.value.name
      host_path = lookup(volume.value, "host_path", null)

      dynamic "docker_volume_configuration" {
        for_each = lookup(volume.value, "docker_volume_configuration", [])
        content {
          scope         = lookup(docker_volume_configuration.value, "scope", null)
          autoprovision = lookup(docker_volume_configuration.value, "autoprovision", null)
          driver        = lookup(docker_volume_configuration.value, "drive", null)
          driver_opts   = lookup(docker_volume_configuration.value, "driver_opts", null)
          labels        = lookup(docker_volume_configuration.value, "labels", null)
        }
      }

      dynamic "efs_volume_configuration" {
        for_each = lookup(volume.value, "efs_volume_configuration", [])
        content {
          file_system_id = lookup(efs_volume_configuration.value, "file_system_id", null)
          root_directory = lookup(efs_volume_configuration.value, "root_directory", null)
        }
      }
    } 
  }
}

## Service
resource "aws_ecs_service" "ecs_service" {
  count                              = var.service_enable
  name                               = var.name
  cluster                            = var.cluster_id
  task_definition                    = aws_ecs_task_definition.ecs_service_task_definition.arn
  desired_count                      = var.number_of_services
  iam_role                           = var.role_arn
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds

  load_balancer {
    target_group_arn = aws_lb_target_group.lb_target_group.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }
}

## Target group
resource "aws_lb_target_group" "lb_target_group" {
  name                 = var.name
  vpc_id               = var.vpc_id
  port                 = "80"
  protocol             = "HTTP"
  deregistration_delay = 15

  health_check {
    interval            = 30
    path                = var.health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 9
  }

  lifecycle {
    ignore_changes = [lambda_multi_value_headers_enabled]
  }
}

## Route 53
resource "aws_route53_record" "route53_records" {
  count   = var.route53_records_zone_id == "" ? 0 : 1
  zone_id = var.route53_records_zone_id
  name    = var.route53_records_name
  type    = "A"

  alias {
    name                   = var.route53_alias_name
    zone_id                = var.route53_alias_zone_id
    evaluate_target_health = false
  }
}

## ELB priority
resource "aws_lb_listener_rule" "lb_listener_rule_priority" {
  count        = var.elb_path == "" && var.elb_priority != "" ? 1 : 0
  listener_arn = var.lb_listener_rule_listener_arn
  priority     = var.elb_priority

  action {
    target_group_arn = aws_lb_target_group.lb_target_group.arn
    type             = "forward"
  }

  condition {
    host_header {
      values = [var.route53_records_name]
    }
  }
}

## ELB with path priority
resource "aws_lb_listener_rule" "lb_listener_rule_path_priority" {
  count        = var.elb_path != "" && var.elb_priority != "" ? 1 : 0
  listener_arn = var.lb_listener_rule_listener_arn
  priority     = var.elb_priority

  action {
    target_group_arn = aws_lb_target_group.lb_target_group.arn
    type             = "forward"
  }

  condition {
    host_header {
      values = [var.route53_records_name]
    }
  }

  condition {
    path_pattern {
      values = [var.elb_path]
    }
  }
}

## ELB
resource "aws_lb_listener_rule" "lb_listener_rule" {
  count        = var.elb_path == "" && var.elb_priority == "" ? 1 : 0
  listener_arn = var.lb_listener_rule_listener_arn

  action {
    target_group_arn = aws_lb_target_group.lb_target_group.arn
    type             = "forward"
  }

  condition {
    host_header {
      values = [var.route53_records_name]
    }
  }
}

## ELB with path
resource "aws_lb_listener_rule" "lb_listener_rule_path" {
  count        = var.elb_path != "" && var.elb_priority == "" ? 1 : 0
  listener_arn = var.lb_listener_rule_listener_arn

  action {
    target_group_arn = aws_lb_target_group.lb_target_group.arn
    type             = "forward"
  }

  condition {
    host_header {
      values = [var.route53_records_name]
    }
  }

  condition {
    path_pattern {
      values = [var.elb_path]
    }
  }
}
