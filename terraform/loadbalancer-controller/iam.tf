data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "role" {
  name               = "${local.base_name}-LbControllerRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = merge(
  {
    "Name" = "${local.base_name}-LbControllerRole"
  },
  local.tags
  )
}

resource "aws_iam_policy" "policy" {
  name        = "${local.base_name}-LbControllerPolicy"
  description = "lb controller用のポリシー"

  policy = file("iam-policy.json")
}

resource "aws_iam_role_policy_attachment" "lbcontroller" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}