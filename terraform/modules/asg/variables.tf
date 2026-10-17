variable "subnet_ids" {
  type = list(string)
}

variable "ec2_role_name" {
  description = "Name of the existing IAM role to attach to EC2 instances"
  type        = string
}

variable "web_sg_id" {
  type = string
}
variable "ami_id" {
  type = string
}
variable "instance_type" {
  type = string
}
variable "key_name" {
  type = string
}
variable "user_data" {
  type = string
}
variable "launch_template_name" {
  type = string
}
variable "asg_name" {
  type = string
}
variable "min_size" {
  type = number
}
variable "max_size" {
  type = number
}
variable "desired_capacity" {
  type = number
}
variable "target_group_arn" {
  type = string
}
