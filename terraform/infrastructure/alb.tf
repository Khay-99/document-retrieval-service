module "alb" {
  source = "../modules/alb"

  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.vpc_public_subnets
  alb_sg_ids        = [module.alb_sg.alb_sg_id]
  internal          = false
  alb_name          = "blueeagle-prod-app-alb"
  target_group_name = "blueeagle-prod-app-tg"
  target_port       = 8080
  listener_port     = 80
  alb_type          = "application"
  target_type       = "instance"
  protocol          = "HTTP"
  default_action_type = "forward"

  # Health Check Configuration
  health_check_enabled           = true
  health_check_path              = "/health"
  health_check_protocol          = "HTTP"
  health_check_matcher           = "200-399"
  health_check_interval           = 30
  health_check_timeout            = 5
  health_check_healthy_threshold   = 2
  health_check_unhealthy_threshold = 2
}
