# 本レポジトリについて

EKSをTerraformで構築するためのコード一式を格納しています。EKSの前提となるVPCなどのTerraformコードも提供します。

## eksctlを使用しないのはなぜですか？

AWSのリソースをTerraformですべてコード化している場合、Terraform以外での作成は極力避けたいと考えるでしょう。
eksctlはAWSも推奨しているツールですが、内部的にはCloudFormationを使用しておりTerraformによる一元管理ができなくなります。
そのため、eksctlではなくTerraformを使用します。

# バージョンについて

以下のバージョンでの動作を確認しています。

- EKS 
  - eks : 1.18
- Terraform
  - Terraform    : v0.13.5
  - AWS provider : v3.12.0

# ドキュメント

より詳しい内容は以下のドキュメントを参照ください。

- [EKS構成について](./documents/configuration.md)
- [使い方](./documents/howtouse.md)
- [各モジュールの説明](./documents/module.md)

## ツールのインストール方法

### terraform

[こちら](https://learn.hashicorp.com/tutorials/terraform/install-cli)のHashiCorpドキュメントを参照ください。
