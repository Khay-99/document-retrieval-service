variable "ResourcePrefix" {}
variable "ami_id" {}
variable "instance_type" {}
variable "key_name" {}
variable "volume_size" {}
variable "volume_type" {}
variable "admin_profile_name" {}
variable "subnet_id" {}
variable "security_group_id" {}
variable "user_data" {}
variable "instance_scope" { default = "public" } # or "private"
variable "instance_name" {}
variable "additional_tags" { default = {} }
