resource "aws_iam_policy" "policy" {
  name        = "${local.base_name}-LbControllerPolicy"
  description = "lb controller用のポリシー"

  policy = file("iam-policy.json")
}
