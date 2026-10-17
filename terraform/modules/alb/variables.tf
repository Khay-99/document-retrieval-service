variable "vpc_id" {
  type = string
}
variable "subnet_ids" {
  type = list(string)
}
variable "alb_sg_ids" {
  type = list(string)
}
variable "internal" {
  type = bool
}
variable "alb_name" {
  type = string
}
variable "target_group_name" {
  type = string
}
variable "alb_type" {
  type    = string
  
}
variable "target_type" {
  type    = string
  
}
variable "protocol" {
  type    = string
  
}
variable "default_action_type" {
  type    = string
 
}
variable "target_port" {
  type    = number
  default = 3000
}
variable "listener_port" {
  type    = number
  default = 80
}
variable "health_check_enabled" {
  type    = bool
  
}
variable "health_check_path" {
  type    = string
  
}
variable "health_check_protocol" {
  type    = string
  
}
variable "health_check_matcher" {
  type    = string
  default = "200-399"
}
variable "health_check_interval" {
  type    = number
  default = 30
}
variable "health_check_timeout" {
  type    = number
  default = 5
}
variable "health_check_healthy_threshold" {
  type    = number
  default = 2
}
variable "health_check_unhealthy_threshold" {
  type    = number
  default = 2
}