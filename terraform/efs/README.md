# efs

## 依存モジュール

- tf-backend
- network

## 説明

`efs`はEFSをデプロイするモジュールです。暗号化を有効にしています。EFSはプラベートサブネットにデプロイされます。セキュリティグループでVPCのCIDRからのインバウンドを許可しています。

EKSでEFSプロビジョナーやEFS CSI Driverを使用する際に活用ください。

### EFS provisioner を使用する場合

`terraform.tfvars`内の`access_points`を`access_points = {}`と設定します。terraform実行後のoutputに`efs_id`が表示されます。これらはEKSのK8sマニフェストで使用するため値を控えておきます。

### EFS CSI Driver を使用する場合

`terraform.tfvars`内の`access_points`を設定します。EFSの用途ごとにEFSアクセスポイントを作成します。用途の数だけ`access_points`にmapを設定してください。terraform実行後のoutputに`efs_id`と`access_points`が表示されます。これらはEKSのK8sマニフェストで使用するため値を控えておきます。

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
| access\_points | アクセスポイントの設定 path=アクセスポイントにするパス(/から絶対パス) owner\_gid=アクセスポイントのgid owner\_uid=アクセスポイントのuid permissions=アクセスポイントのパーミッション | <pre>map(object({<br>    path        = string<br>    owner_gid   = number<br>    owner_uid   = number<br>    permissions = string<br>  }))</pre> | `{}` | no |
| base\_name | 作成するリソースに付与する接頭語 | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| access\_point\_id | n/a |
| efs\_id | n/a |

