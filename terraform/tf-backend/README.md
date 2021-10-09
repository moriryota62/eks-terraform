# tf-backend

## 依存モジュール

なし

## 説明

`tf-backend`はtfstateを格納するS3バケットと排他制御のためのDyanoDBテーブルを作成するモジュールです。

本モジュールのtfstateはterraformを実行した端末のカレントディレクトリに作成されます。そのため、本モジュールのtfstateの扱いには注意してください。

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

## Outputs

No output.