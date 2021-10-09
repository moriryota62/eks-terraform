# eks-node-group

## 依存モジュール

- tf-backend
- network
- eks

## 説明

`eks-node-group`はEKSのマネージドワーカーをデプロイするモジュールです。ワーカーはプラベートサブネットにデプロイされます。`desired_size`は初回デプロイ時のみ設定でき、以降は値を変えても無視されます。これはワーカーのノード台数はHPAなど、Terraform外で変更されることがあるためあえてこうしています。

sshキーを指定する場合、terraform実行前にデプロイするリージョンでkeyペアを作成しておいてください。モジュール内でkeyペアは作成しません。

複数のノードグループを作成したい場合、本モジュールのディレクトリを複製し違う`node_role`を指定してデプロイしてください。

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
| allow\_security\_group\_ids | ノードにsshを許可するセキュリティグループ | `list(string)` | n/a | yes |
| base\_name | 作成するリソースに付与する接頭語 | `string` | n/a | yes |
| desired\_size | ノードの希望数 | `number` | n/a | yes |
| disk\_size | ノードのローカルディスク容量 | `number` | n/a | yes |
| instance\_type | ノードのインスタンスタイプ | `string` | n/a | yes |
| key\_pair | ノードにsshするkeyペア | `string` | n/a | yes |
| max\_size | ノードの最大数 | `number` | n/a | yes |
| min\_size | ノードの最小数 | `number` | n/a | yes |
| node\_role | ノードグループの役割 | `string` | n/a | yes |

## Outputs

No output.