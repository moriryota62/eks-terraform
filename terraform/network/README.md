# network

## 依存モジュール

- tf-backend

## 説明

`network`はVPCとパブリックサブネットおよびプライベートサブネットを構築するterraformモジュールです。インターネットゲートウェイやNATゲートウェイ、ECRとS3へのエンドポイントも構築します。このモジュールで作成した`VPCのID`や`サブネットのID`は他のモジュールでも使用します。

[クラスター VPC に関する考慮事項(https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/network_reqs.html)]に記載さているタグをVPCおよびサブネットに付与します。

```
# EKSからサブネットを認識するためのタグ
"kubernetes.io/cluster/${var.cluster_name}" = "shared"

# type:LB使用のため
## for public subnet
"kubernetes.io/role/elb" = 1
## for private subent
"kubernetes.io/role/internal-elb" = 1
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13.5 |

## Providers

| Name | Version |
|------|---------|
| aws | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| base\_name | 作成するリソースに付与する接頭語 | `string` | n/a | yes |
| subnet\_private\_cidrs | プライベートサブネットのアドレス帯 | `list(string)` | n/a | yes |
| subnet\_public\_cidrs | パブリックサブネットのアドレス帯 | `list(string)` | n/a | yes |
| vpc\_cidr | VPCのネットワークアドレス帯 | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| private\_subnet\_ids | n/a |
| public\_subnet\_ids | n/a |
| vpc\_cidr | n/a |
| vpc\_id | n/a |
