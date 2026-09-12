data "aws_iam_role" "ec2_role" {
  name = var.ec2_role_name
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.ec2_role_name}-instance-profile"
  role = data.aws_iam_role.ec2_role.name

  tags = {
    Name      = "${var.ec2_role_name}-instance-profile"
    Project   = "BlueEagle"
    ManagedBy = "Terraform"
    Owner     = "Platform"
  }
}

resource "aws_launch_template" "web_lt" {
  name_prefix            = var.launch_template_name
  image_id               = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [var.web_sg_id]

  iam_instance_profile {
  name = aws_iam_instance_profile.ec2_instance_profile.name
}
  user_data = base64encode(var.user_data)

  monitoring { enabled = true }

  lifecycle { create_before_destroy = true }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.launch_template_name}-instance"
      Environment = "prod"
      Project     = "BlueEagle"
      ManagedBy   = "Terraform"
      Owner       = "Platform"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name        = "${var.launch_template_name}-volume"
      Environment = "prod"
      Project     = "BlueEagle"
      ManagedBy   = "Terraform"
      Owner       = "Platform"
    }
  }
}

resource "aws_autoscaling_group" "web_asg" {
  name                = var.asg_name
  max_size            = var.max_size
  min_size            = var.min_size
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = var.subnet_ids
  health_check_type   = "EC2" # you can also use "ELB" if you have an ELB health check configured
  health_check_grace_period = 180
  force_delete        = true
  target_group_arns         = [var.target_group_arn]

  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

  wait_for_capacity_timeout = "10m"

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 60
    }

    
  }

  tag {
    key                 = "Name"
    value               = var.asg_name
    propagate_at_launch = true
  }

  lifecycle { create_before_destroy = true }
}

