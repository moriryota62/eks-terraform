resource "aws_route53_record" "this" {
  for_each = var.recods != null ? var.recods : {}

  zone_id = aws_route53_zone.this.zone_id
  name    = each.value.name
  type    = "A"

  alias {
    name                   = each.value.elb_name
    zone_id                = each.value.elb_zone_id
    evaluate_target_health = true
  }
}