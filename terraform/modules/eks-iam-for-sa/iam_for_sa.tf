data "aws_iam_policy_document" "this" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(var.openid_connect_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.k8s_namespace}:${var.k8s_sa}"]
    }

    principals {
      identifiers = [var.openid_connect_provider_arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "this" {
  assume_role_policy = data.aws_iam_policy_document.this.json
  name               = "${var.base_name}-SAIAM-${var.k8s_namespace}-${var.k8s_sa}"

  tags = merge(
    {
      "Name"           = "${var.base_name}-SAIAM-${var.k8s_namespace}-${var.k8s_sa}",
      "Namespace"      = var.k8s_namespace,
      "ServiceAccount" = var.k8s_sa
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "this" {
  policy_arn = var.attach_policy_arn
  role       = aws_iam_role.this.id
}