output "arn" {
  value = aws_launch_template.launchtemplate1.arn
}
/*
output "public_ip" {
  value = aws_launch_template.launchtemplate1
}
*/

output "alb_dns_name" {
  description = "alb dns"
  value       = aws_lb.alb1.dns_name
}