# route53

## 依存モジュール

- tf-backend
- network

## 説明

`route53`はRoute53のホストゾーンやレコードを作成するモジュールです。

ホストゾーンのみ作成したい場合は`recode.tf`をコメントアウトしてください。

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
| recods | 登録するレコード情報 | <pre>map(object({<br>    name        = string<br>    elb_name    = string<br>    elb_zone_id = string<br>  }))</pre> | `null` | no |
| zone\_name | ホストゾーンの名前 | `string` | n/a | yes |

## Outputs

No output.


