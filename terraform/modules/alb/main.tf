resource "aws_lb" "web_alb" {
  name               = var.alb_name
  internal           = var.internal
  load_balancer_type = var.alb_type
  security_groups    = var.alb_sg_ids
  subnets            = var.subnet_ids

  tags = { Name = var.alb_name }
}

resource "aws_lb_target_group" "web_tg" {
  name        = var.target_group_name
  port        = var.target_port
  protocol    = var.protocol
  target_type = var.target_type
  vpc_id      = var.vpc_id

  health_check {
    enabled             = var.health_check_enabled
    path                = var.health_check_path
    protocol            = var.health_check_protocol
    matcher             = var.health_check_matcher
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
  }

  tags = { Name = var.target_group_name }
}

resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = var.listener_port
  protocol          = "HTTP"

  default_action {
    type             = var.default_action_type
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}