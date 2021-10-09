# eks

## 依存モジュール

- tf-backend
- network

## 説明

`eks`はEKSをデプロイするモジュールです。etcdの暗号化を有効にしています。EKSはパブリックサブネットおよびプライベートサブネットと関連付けられます。

本モジュールではEKSマネージドワーカーおよびFargateで使用するIAMロールも作成します。

なお、EKSのデプロイには10分ほどかかります。

**注意**  

Proxy環境下で実行すると`tls_certificate`に関するエラーが出ます。これはTerraformのissueにも上がっています。

[[feature request] Support HTTP proxy for tls_certificate data source](https://github.com/hashicorp/terraform-provider-tls/issues/96)

現状（2021/10月時点）、Proxy環境下で本モジュール実行する場合、[iam_role_for_sa.tf](./iam_role_for_sa.tf)をコメントアウトしてください。また、[output.tf](./output.tf)の`openid_connect_provider_url`および`openid_connect_provider_arn`もコメントアウトしてください。

これによりIAM for SAが使用できなくなります。IAM for SAを使用したい場合は手動で設定してください。

[IAM roles for service accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)

## KUBECONFIGの設定

EKSに接続するためkubeconfigを設定します。

以下のコマンドを実行します。

``` sh
aws eks --region $REGION update-kubeconfig --name $PJ-$ENV --kubeconfig ~/.kube/config_$PJ-$ENV
```

その後、使用するkubeconfigを以下の環境変数で設定します。

``` sh
export KUBECONFIG=~/.kube/config_$PJ-$ENV
```

以下コマンドでEKSへの接続を確認します。

``` sh
kubectl get node
```

ノードが表示されれば接続できています。

以降はEKS(K8s)の設定をします。
基本的な機能の実装方法については[こちら](../../documents/manifests/)にドキュメントを用意していますので参照ください。

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13.5 |

## Providers

| Name | Version |
|------|---------|
| aws | n/a |
| terraform | n/a |
| tls | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| base\_name | 作成するリソースに付与する接頭語 | `string` | n/a | yes |
| eks\_version | 作成するEKSのバージョン | `string` | n/a | yes |
| enabled\_cluster\_log\_types | ログ収集を有効にするマスターコンポーネント | `list(string)` | n/a | yes |
| endpoint\_private\_access | VPC内からEKSのAPIサーバーへのアクセスを許可するか | `bool` | n/a | yes |
| endpoint\_public\_access | VPC外からEKSのAPIサーバーへのアクセスを許可するか | `bool` | n/a | yes |
| public\_access\_cidrs | VPC外からEKSのAPIサーバーへのアクセスを許可するCIDRリスト | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| cluster\_name | n/a |
| fargate\_iam\_arn | n/a |
| nodegroup\_iam\_arn | n/a |
| openid\_connect\_provider\_arn | n/a |
| openid\_connect\_provider\_url | n/a |
