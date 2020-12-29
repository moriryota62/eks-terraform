resource "aws_iam_policy" "policy" {
  name        = "${var.base_name}-LbControllerPolicy"
  description = "lb controller用のポリシー"

  # 以下ファイルパスはterrafrom applyを実行するディレクトリからの相対パスで記載
  policy = file("../modules/alb-iam/iam-policy.json")
}
