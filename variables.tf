variable "name" {
  description = "Name of the service"
}

variable "container_definition_template" {
  description = "Task container definition"
}

variable "container_definition_vars" {
  description = "Container definition vars"
  type        = "map"
}

variable "service_enable" {
  description = "Active o deactivate service"
}

variable "cluster_id" {
  description = "Id of the cluster"
}

variable "number_of_services" {
  description = "Numer of services to deploy in the cluster"
}

variable "role_arn" {
  description = "Id of the role to deploy the service"
}

variable "deployment_minimum_healthy_percent" {
  description = "Minimum healthy percent of the service in the cluster"
}

variable depends_on {
  default = []

  type = "list"
}

variable "health_check_grace_period_seconds" {
  description = "Health check grace period in seconds. It is the time that the app has to start."
  default     = 300
}

variable "container_name" {}
variable "container_port" {}
variable "vpc_id" {}

variable "health_check_path" {
  default = "/health"
}

variable "route53_records_zone_id" {
  default = ""
}
variable "route53_records_name" {}
variable "route53_alias_name" {}
variable "route53_alias_zone_id" {}
variable "lb_listener_rule_listener_arn" {}

variable "volume" {
  default = []
}

variable "elb_path" {
  default = ""
}