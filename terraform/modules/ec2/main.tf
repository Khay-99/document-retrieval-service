resource "aws_instance" "app" {
  ami                  = var.ami_id
  instance_type        = var.instance_type
  key_name             = var.key_name
  subnet_id            = var.subnet_id
  security_groups      = [var.security_group_id]
  iam_instance_profile = var.admin_profile_name
  user_data            = var.user_data

  root_block_device {
    volume_size = var.volume_size
    volume_type = var.volume_type
  }

  tags = merge(
    {
      Name = "${var.ResourcePrefix}-${var.instance_scope}-${var.instance_name}"
    },
    var.additional_tags
  )
}
