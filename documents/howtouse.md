- [前提](#前提)
- [環境変数の設定](#環境変数の設定)

本レポジトリのTerraformコードを利用する方法を説明します。

まずは本レポジトリを任意の場所でクローンしてください。なお、以降の手順では任意のディレクトリのパスを`$CLONEDIR`環境変数として進めます。

``` sh
export CLONEDIR=`pwd`
git clone https://github.com/moriryota62/eks-terraform.git
cd eks-terraform
export DIR=`pwd`
```

# 前提

- 作業端末でAWS CLIがで実行できる
- 作業に使用するIAMユーザはAdministratorAccessなど強い権限を持っている（IAMの作成などが可能である）
- 作業端末にterraformがインストールされている
- 作業端末にkubectlがインストールされている

# 環境変数の設定

以降の手順で複数のファイルで使用する基本設定値を環境変数に設定しておきます。

``` sh
export REGION=us-east-2
export PJ=pj
export ENV=env
export OWNER=owner
```

# tfバックエンドの作成

Terraformのtfstateを保存するバックエンドをS3およびDynamoDBを使って構築します。

バックエンド作成用のコードを記述したディレクトリに移動してください。

``` sh
cd $DIR/terraform/tf-backend
```

`tf-backend.tf`ファイルを編集します。編集が必要な箇所はさきほど環境変数に設定した基本設定値です。以下コマンドで置換できるようにしてあります。

**macの場合**

``` sh
sed -i "" -e 's:REGION:'$REGION':g' tf-backend.tf
sed -i "" -e 's:PJ:'$PJ':g' tf-backend.tf
sed -i "" -e 's:ENV:'$ENV':g' tf-backend.tf
sed -i "" -e 's:OWNER:'$OWNER':g' tf-backend.tf
```

上記修正したらTerraformを実行します。

``` sh
terraform init
terraform plan
terraform apply
> yes
```

上記実行すると`pj-env-tfstate`（pjおよびenvは環境変数に自身で設定した値に読み替えてください）という名前のS3バケットと`pj-env-tfstate-lock`という名前のDynamoDBのテーブルが作成されます。
S3バケットはtfstateを保存する用のバケットです。DynamoDBはstateの排他制御に使用します。
以降のTerraformで作成するリソースの情報はこの`pj-env-tfstate`バケットの中に保存されます。
しかし、この**tfバックエンドを構築した際のtfstateはカレントディレクトリに作られます。**
以下のようにカレントディレクトリを確認するとファイルが確認できるはずです。
このtfstateファイルは削除しないように注意してください。

``` sh
ll
```

表示例

```
-rw-r--r--  1 moriryota62  staff  1182 11 13 22:49 tf-backend.tf
-rw-r--r--  1 moriryota62  staff  4279 11 21 11:23 terraform.tfstate
-rw-r--r--  1 moriryota62  staff  2049 11 21 11:23 terraform.tfstate.backup
```

# パラメータ設定

EKSおよび周辺リソースを構築します。まずはmainとなるディレクトリに移動します。

``` sh
cd $DIR/terraform/main
```

まずは`local_values.tf`の基本設定値を置換で設定します。

**macの場合**

``` sh
sed -i "" -e 's:REGION:'$REGION':g' local_values.tf
sed -i "" -e 's:PJ:'$PJ':g' local_values.tf
sed -i "" -e 's:ENV:'$ENV':g' local_values.tf
sed -i "" -e 's:OWNER:'$OWNER':g' local_values.tf
```

その後、`local_values.tf`および`maint.tf`を修正します。
`local_values.tf`には作成するリソースの内、値を決める必要のあるパラメータをまとめています。
`maint.tf`はAWSリソースを作成するモジュールを読み込みます。不要なモジュールがあればブロックごとコメントアウトしてください。

以下、モジュールごとに修正のポイントを解説します。

## network

EKSをデプロイするVPCやサブネットを作成します。

既存のネットワークを使用する場合、`main.tf`の`module "network"`をブロックごとコメントアウトしてください。
また、その場合は`maint.tf`内にある`module.network〜`でパラメータを読み込んでいる箇所を自身の環境に合わせた値へ修正してください。
たとえば、VPC-IDが`vpc-01b9832`だった場合、`main.tf`内の`module.network.vpc_id`を`vpc-01b9832`にすべて置換します。

新規にネットワークを作成する場合、`local_value.tf`内のnetwork module関連パラメータを指定してください。
なお、EKSの仕様上ことなる2つ以上のAZが必要となります。そのため、各サブネットは必ず2つ以上指定してください。

## bastion

踏み台サーバを作成します。

`local_value.tf`内のbastion module関連パラメータを指定してください。
なお、sshキーを指定する場合、terraform実行前にデプロイするリージョンでkeyペアを作成しておいてください。モジュール内でkeyペアは作成しません。
インスタンスの自動起動/停止が不要な場合は`cloudwatch_enable_schedule`をfalseにします。terraform実行後のoutputに踏み台サーバのIPアドレスが表示されます。

複数の踏み台サーバを作成したい場合、`maint.tf`内の`module "bastion"`をブロックごとコピペし、モジュール名や`local.〜`のパラメータ名を変更し、`local_value.tf`で値を設定してください。

## kms

EFSやEKSのSecretリソースを暗号化するキーを発行します。

KMSについてのパラメータはとくに指定しません。

## efs

複数Podでデータを共有するためのEFSを作成します。

EKSでのEFSの扱いかたによって`local_value.tf`内のefs module関連パラメータの指定が変わります。

### EFS provisoner を使用する場合

`local_value.tf`内の`efs_access_points`はとくに設定不要です。コメントアウトするか、`efs_access_points = {}`と設定します。terraform実行後のoutputに`efs_id`が表示されます。これらはEKSのK8sマニフェストで使用するため値を控えておきます。

### EFS CSI Driver を使用する場合

`local_value.tf`内の`efs_access_points`を設定します。EFSの用途ごとにEFSアクセスポイントを作成します。用途の数だけ`efs_access_points`にmapを設定してください。terraform実行後のoutputに`efs_id`と`access_points`が表示されます。これらはEKSのK8sマニフェストで使用するため値を控えておきます。

## eks

EKSを作成します。

`local_value.tf`内のeks module関連パラメータを指定してください。

## node-group

EKSのマネージドノードグループを作成します。

`local_value.tf`内のnode-group module関連パラメータを指定してください。
なお、sshキーを指定する場合、terraform実行前にデプロイするリージョンでkeyペアを作成しておいてください。モジュール内でkeyペアは作成しません。

複数のノードグループを作成したい場合、`maint.tf`内の`module "worker-node"`をブロックごとコピペし、モジュール名や`local.〜`のパラメータ名を変更し、`local_value.tf`で値を設定してください。

## fargate

EKSのFargateプロファイルを作成します。

Fargateを使用しない場合、`main.tf`の`module "fargate"`をブロックごとコメントアウトしてください。

Fargateを使用する場合、`local_value.tf`内のfargate module関連パラメータを指定してください。

複数のFargateプロファイルを作成したい場合、`maint.tf`内の`module "fargate"`をブロックごとコピペし、モジュール名や`local.〜`のパラメータ名を変更し、`local_value.tf`で値を設定してください。

## iam-for-sa

AWSのIAMロールとK8sのServiceAccountを連携する設定を行います。

iam for saを設定しない場合、`main.tf`の`module "iam-for-sa"`をブロックごとコメントアウトしてください。

iam for saを設定する場合、`local_value.tf`内のiam for sa module関連パラメータを指定してください。

複数のIAMロールおよびServiceAccountを連携する場合、`maint.tf`内の`module "iam-for-sa"`をブロックごとコピペし、モジュール名や`local.〜`のパラメータ名を変更し、`local_value.tf`で値を設定してください。

# Terraform実行

`local_values.tf`および`maint.tf`を修正したらTerraformを実行します。

``` sh
terraform init
terraform plan
terraform apply
> yes
```

なお、EKSの作成には10分以上かかるためapplyをyesしてからすべてのリソース作成が完了するまで20分ほどかかります。
完了すると以下のように出力されます。

```
Apply complete! Resources: 61 added, 0 changed, 0 destroyed.
Releasing state lock. This may take a few moments...

Outputs:

access_points = []
bastion_eip = 18.195.116.73
efs_id = fs-9fc0aft7
```

# KUBECONFIGの設定

EKSに接続するためkubeconfigを設定します。

以下のコマンドを実行します。

``` sh
aws eks --region $REGION update-kubeconfig --name $PJ-$ENV --kubeconfig ~/.kube/config_$PJ-$ENV
aws eks --region us-east-2 update-kubeconfig --name PJ-ENV --kubeconfig ~/.kube/config_PJ-ENV
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
基本的な機能の[実装方法](./manifests.md)を用意していますのでそちらもご活用ください。
