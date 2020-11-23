- [使い方](#使い方)

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

# EKSの作成

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
自身の環境にあわせてパラメータを指定してください。

`main.tf`には作成するリソースの読み出しや`local_values.tf`で宣言した値の代入などを行います。
ノードグループやFargateプロファイル、iam-for-saなどを複数作りたい場合はモジュール部分をまるごとコピペし、モジュール名やlocalの変数名を変えて`local_value.tf`に自身で追加して設定してください。
また、不要なモジュール部分はまるごとコメントアウトすればそれらのリソースは作成されません。

`local_values.tf`および`maint.tf`を修正したらTerraformを実行します。

``` sh
terraform init
terraform plan
terraform apply
> yes
```

なお、EKSの作成には10分以上かかるためapplyをyesしてから完了するまで20分ほどかかります。

# KUBECONFIGの設定

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
基本的な機能を実践するサンプルマニフェストを用意していますのでそちらもご活用ください。


---

``` sh
aws eks --region $REGION update-kubeconfig --name $PJ-$ENV --kubeconfig ~/.kube/config_CLUSTERNAME
aws eks --region $REGION update-kubeconfig --name PJ-NAME-ENV --kubeconfig ~/.kube/config_PJ-NAME-ENV
aws eks --region us-east-2 update-kubeconfig --name PJ-ENV --kubeconfig ~/.kube/config_PJ-ENV
```




- [ ] network
  - [ ] api serverへは指定したCIDRからのみアクセスできる
  - [X] パブリックサブネットとプライベートサブネットを関連付ける
- log
  - [X] すべてのマスターコンポーネントのログを取得する
- worker
  - [X] workerはすべてプライベートサブネットに配置する
  - [X] managed workerを使用する
  - [X] Cluster Autoscallerにも対応する （managed workerだと自動で付与される）
  - [X] workerは`infra`、`app`の2つのグループを構成
  - [X] 各グループに`role: infra`、`role: app`のラベルをつける
  - [X] また、fargateのワーカーも用意する
    - [X] fargateはdefaultのnamespaceに紐づく
    - [X] fargateには`faragete: true`のラベルがついているPodだけ起動する 
  - [ ] ec2のワーカーには任意のsshキーでアクセスできる
- security
  - [ ] Pod to Iamを使用する
  - [X] secretのkms暗号化を使用する
  - [ ] Pod SGも使用できる

- [ ] fargateでPodが起動できる
- [ ] EBSのDVPできる
- [_] EFSのDVPできる
- [_] CAできる
- [_] type:ALBのServiceつくれる
- [_] Fluxできる