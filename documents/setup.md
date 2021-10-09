- [前提](#前提)
- [環境変数の設定](#環境変数の設定)
- [tfバックエンドの作成](#tfバックエンドの作成)
- [Terraform実行](#terraform実行)

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

以降の手順で複数のファイルで使用する基本設定値を環境変数に設定しておきます。`REGION`、`PJ`、`ENV`、`OWNER`は好きな値に設定してください。東京リージョン（ap-northeast-1）を使用する場合は置換しないでも良いです。

``` sh
export REGION=us-east-2
export PJ=pj
export ENV=env
export OWNER=owner
```

以下コマンドで環境変数を置換

**Linuxの場合**

``` sh
cd $DIR/terraform/
find ./ -type f -exec grep -l 'ap-northeast-1' {} \; | xargs sed -i -e 's:ap-northeast-1:'$REGION':g'
find ./ -type f -exec grep -l 'project' {} \; | xargs sed -i -e 's:project:'$PJ':g'
find ./ -type f -exec grep -l 'environment' {} \; | xargs sed -i -e 's:environment:'$ENV':g'
find ./ -type f -exec grep -l 'owner' {} \; | xargs sed -i -e 's:owner:'$OWNER':g'
```

**macの場合**

``` sh
cd $DIR/terraform/
find ./ -type f -exec grep -l 'ap-northeast-1' {} \; | xargs sed -i "" -e 's:ap-northeast-1:'$REGION':g'
find ./ -type f -exec grep -l 'project' {} \; | xargs sed -i "" -e 's:project:'$PJ':g'
find ./ -type f -exec grep -l 'environment' {} \; | xargs sed -i "" -e 's:environment:'$ENV':g'
find ./ -type f -exec grep -l 'owner' {} \; | xargs sed -i "" -e 's:owner:'$OWNER':g'
```

# tfバックエンドの作成

Terraformのtfstateを保存するバックエンドをS3およびDynamoDBを使って構築します。

バックエンド作成用のコードを記述したディレクトリに移動してください。

``` sh
cd $DIR/terraform/tf-backend
```

Terraformを実行します。

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
ll terraform*
```

表示例

```
-rw-r--r--  1 moriryota62  staff   156 10  3 17:28 terraform.tfstate
-rw-r--r--  1 moriryota62  staff  5023 10  3 17:28 terraform.tfstate.backup
-rw-r--r--  1 moriryota62  staff    34 10  7 23:12 terraform.tfvars
```

# Terraform実行

[terraform](../terraform/))ディレクトリ以下に各モジュールを配置しています。デプロイしたいモジュールディレクトリに移動し、`terraform.tfvars`に値を設定してください。その後、以下コマンドterraformを実行してください。

``` sh
terraform init
terraform plan
terraform apply
> yes
```
