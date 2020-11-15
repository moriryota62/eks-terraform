//resource "aws_iam_role" "fargate_profile" {
//  name = "${var.base_name}-fargate-profile"
//
//  assume_role_policy = jsonencode({
//    Statement = [{
//      Action = "sts:AssumeRole"
//      Effect = "Allow"
//      Principal = {
//        Service = "eks-fargate-pods.amazonaws.com"
//      }
//    }]
//    Version = "2012-10-17"
//  })
//}
//
//resource "aws_iam_role_policy_attachment" "eks_fargate_pod_execution_role" {
//  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
//  role       = aws_iam_role.fargate_profile.name
//}