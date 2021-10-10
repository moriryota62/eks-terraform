# eks-iam-for-sa_container-insights-log

## 依存モジュール

- tf-backend
- network
- eks

## 説明

`eks-iam-for-sa_container-insights-log`は[Container Insights](https://docs.aws.amazon.com/ja_jp/AmazonCloudWatch/latest/monitoring/ContainerInsights.html)でログ収集を行うためのIAMロールを作成します。

[terraform.tfvars](./terraform.tfvars)に設定してある`k8s_namespace`および`k8s_sa`はそのまま`amazon-cloudwatch`および`fluent-bit`を指定ください。

本モジュールのディレクトリをコピーして別用途のIAM for SAを設定できます。その場合、[iam_policy.json](./iam_policy.json)や[iam_policy.tf](./iam_policy.tf)も修正してください。

**注意**

Proxy環境下でIAM for SAのOIDCプロバイダ設定を手動でした場合、[iam_for_sa.tf](./iam_for_sa.tf)のdata.aws_iam_policy_document.this内の以下設定を手動で設定してください。

- statement.condition.variable:
- statement.principals.identifiers 

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13.5 |

## Providers

| Name | Version |
|------|---------|
| aws | n/a |
| terraform | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| base\_name | 作成するリソースに付与する接頭語 | `string` | n/a | yes |
| k8s\_namespace | iamと紐付けるk8sのSAが属するNamespace | `string` | n/a | yes |
| k8s\_sa | iamと紐付けるk8sのSA | `string` | n/a | yes |
| role\_name | IAMロール名 | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| role\_name | n/a |
