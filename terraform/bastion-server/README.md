# bastion-server

## 依存モジュール

- tf-backend
- network

## 説明

`bastion-server`はパブリックサブネットに踏み台サーバを構築するモジュールです。踏み台サーバにはEIPを付与します。SSMセッションマネージャで接続することもできます。

sshキーを指定する場合、terraform実行前にデプロイするリージョンでkeyペアを作成しておいてください。モジュール内でkeyペアは作成しません。

userdataで`docker`と`kubectl`をインストールします。

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
| base\_name | リソース群に付与する接頭語 | `string` | n/a | yes |
| cloudwatch\_enable\_schedule | 踏み台サーバーを自動起動/停止するか | `bool` | `false` | no |
| cloudwatch\_start\_schedule | 踏み台サーバーを自動起動する時間。時間の指定はUTCのため注意 | `string` | `"cron(0 0 ? * MON-FRI *)"` | no |
| cloudwatch\_stop\_schedule | 踏み台サーバーを自動停止する時間。時間の指定はUTCのため注意 | `string` | `"cron(0 10 ? * MON-FRI *)"` | no |
| ec2\_instance\_type | 踏み台サーバーのインスタンスタイプ | `string` | n/a | yes |
| ec2\_key\_name | 踏み台サーバーのインスタンスにsshログインするためのキーペア名 | `string` | `null` | no |
| ec2\_root\_block\_volume\_size | 踏み台サーバーのルートデバイスの容量(GB) | `number` | n/a | yes |
| sg\_allow\_access\_cidrs | 踏み台サーバーへのアクセスを許可するCIDRリスト | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| bastion\_eip | n/a |
| bastion\_sg\_id | n/a |