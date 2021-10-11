data "aws_iam_policy_document" "this" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(data.terraform_remote_state.eks.outputs.openid_connect_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.k8s_namespace}:${var.k8s_sa}"]
    }

    principals {
      identifiers = [data.terraform_remote_state.eks.outputs.openid_connect_provider_arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "this" {
  assume_role_policy = data.aws_iam_policy_document.this.json
  name               = var.role_name

  tags = {
    "Name"           = var.role_name,
    "Namespace"      = var.k8s_namespace,
    "ServiceAccount" = var.k8s_sa
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.this.id
}

