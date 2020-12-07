#resource "aws_route53_record" "this" {
#  for_each = var.recode
#
#  zone_id = aws_route53_zone.this.zone_id
#  name    = each.value.name
#  type    = "A"
#  ttl     = "300"
#
#  alias {
#    name                   = var.elb_name
#    zone_id                = var.elb_zone_id
#    evaluate_target_health = true
#  }
#}