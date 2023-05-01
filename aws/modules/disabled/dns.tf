// create internal hosted zone
resource "aws_route53_zone" "internal" {
  name = "cloudfoxable.internal"
  comment = "internal zone"
  force_destroy = true
  vpc {
    vpc_id = aws_vpc.cloudfox.id
  }
}

# resource "aws_route53_record" "ec2-ssrf" {
#   zone_id = aws_route53_zone.internal.zone_id
#   name = "messi.cloudfoxable.internal"
#   type = "A"
#   ttl = "300"
#   records = ["${aws_instance.ec2-ssrf.private_ip}"]
# }


// create records in the internal hosted zone that map my apprunner services
# resource "aws_route53_record" "apprunner-public" {
#   zone_id = aws_route53_zone.internal.zone_id
#   name = "ronaldo.cloudfoxable.internal"
#   type = "A"
#   ttl = "300"
#   records = ["${aws_apprunner_service.cfapprunner-public.dns_target}"]
# }


# resource "aws_route53_record" "apprunner-private" {
#   zone_id = aws_route53_zone.internal.zone_id
#   name = "maradona.cloudfoxable.internal"
#   type = "A"
#   ttl = "300"
#   records = ["${aws_apprunner_service.cfapprunner-private.dns_target}"]
# }

# resource "aws_route53_record" "challenge-ecs" {
#     zone_id = aws_route53_zone.internal.zone_id
#     name = "messi.cloudfoxable.internal"
#     type = "CNAME"
#     ttl = "300"
#     records = [aws_ecs_service.challenge-ecs-ec2-ssrf.service.client_alias]
# }

# resource "aws_route53_record" "challenge-ecs-ssrf-ec2" {
#     zone_id = aws_route53_zone.internal.zone_id
#     name = "mbappe.cloudfoxable.internal"
#   type    = "CNAME"
#     ttl = "300"
#     records = ["${aws_instance.ecs-ec2-ssrf.load_balancers.0.dns_name}"]
# }

# resource "aws_route53_record" "challenge-ecs-ssrf-fargate" {
#     zone_id = aws_route53_zone.internal.zone_id
#     name = "neymar.cloudfoxable.internal"
#   type    = "CNAME"
#     ttl = "300"
#     records = ["${aws_ecs_service.challenge-ecs-fargate-ssrf.load_balancers.0.dns_name}"]
# }