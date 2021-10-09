# eks-fargate

## 依存モジュール

- tf-backend
- network
- eks

## 説明

`eks-fargate`はEKSのFargateプロファイルを作成するモジュールです。Fargateはプライベートサブネットに関連づけられています。

あるNamespaceのすべてのPodをFargateで動かしたい場合`namespace`のみ設定し、`labels`は空（{}）を指定してください。ちなみに、`namespace`の設定は必須です。

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
| eks-fargate\_profiles | Fargateプロファイルの設定。Fargateプロファイルを作成しない場合は空マップ「{}」にする。 | <pre>map(object({<br>    namespace    = string<br>    labels       = map(string)<br>  }))</pre> | n/a | yes |

## Outputs

No output.