output "asg_id" { value = aws_autoscaling_group.web_asg.id }
output "asg_name" { value = aws_autoscaling_group.web_asg.name }
output "launch_template_id" { value = aws_launch_template.web_lt.id }
output "launch_template_name" { value = aws_launch_template.web_lt.name }