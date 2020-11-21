- [使い方](#使い方)

# 使い方

本レポジトリのTerraformコードを利用する方法を説明します。


まずは本レポジトリを任意の場所でクローンしてください。なお、以降の手順では任意のディレクトリのパスを`$CLONEDIR`環境変数として進めます。

``` sh
export CLONEDIR=`pwd`
git clone https://github.com/moriryota62/eks-terraform.git
cd eks-terraform
export DIR=`pwd`
```

## 環境変数の設定

以降の手順で使用する変数を環境変数で設定して起きます。

``` sh
export REGION=us-east-2
export PJ=PJ
export OWNER=OWNER
export ENV=ENV
```

## Terraform

以下ファイルの内容を確認します。VPCのCIDRなど自身の環境にあわせて修正してください。

``` sh
cd $DIR/terraform/main
vi main.tf
```

terraformを実行します。

``` sh
terraform plan
terraform apply
```

アウトプットを環境に設定

``` sh
export VPCID=<vpc_id>
export PUBLICSUBNET1=<public_subent_ids 1>
export PUBLICSUBNET2=<public_subent_ids 2>
export PRIVATESUBNET1=<private_subent_ids 1>
export PRIVATESUBNET2=<private_subent_ids 2>
export EFSID=<efs_id>
```

KMSARNの値は控えておく

## eksctl

``` sh
export YOURCIDR=<作業端末のグローバルIP>
export KEYNAME=<ssh キーペアの名前>
```

``` sh
cd $DIR/eksctl
sed -i "" -e 's:REGION:'$REGION':g' sample-cluster.yaml
sed -i "" -e 's:PJ:'$PJ':g' sample-cluster.yaml
sed -i "" -e 's:ENV:'$ENV':g' sample-cluster.yaml
sed -i "" -e 's:VPCID:'$VPCID':g' sample-cluster.yaml
sed -i "" -e 's:PUBLICSUBNET1:'$PUBLICSUBNET1':g' sample-cluster.yaml
sed -i "" -e 's:PUBLICSUBNET2:'$PUBLICSUBNET2':g' sample-cluster.yaml
sed -i "" -e 's:PRIVATESUBNET1:'$PRIVATESUBNET1':g' sample-cluster.yaml
sed -i "" -e 's:PRIVATESUBNET2:'$PRIVATESUBNET2':g' sample-cluster.yaml
sed -i "" -e 's:YOURCIDR:'$YOURCIDR':g' sample-cluster.yaml
sed -i "" -e 's:KEYNAME:'$KEYNAME':g' sample-cluster.yaml
```

KMSARNの値を修正する

``` sh
vi sample-cluster.yaml
```

設定ファイルの作成
[公式サンプル集](https://github.com/weaveworks/eksctl/tree/master/examples)

クラスタ作成

``` sh
eksctl create cluster -f sample-cluster.yaml
```

``` sh
aws eks --region $REGION update-kubeconfig --name $PJ-$ENV --kubeconfig ~/.kube/config_CLUSTERNAME
aws eks --region $REGION update-kubeconfig --name PJ-NAME-ENV --kubeconfig ~/.kube/config_PJ-NAME-ENV
aws eks --region us-east-2 update-kubeconfig --name PJ-ENV --kubeconfig ~/.kube/config_PJ-ENV
```

接続確認

``` sh
kubectl get node
```

## k8s動作確認

### fargateでPod起動

``` sh
kubectl apply -f $DIR/k8s-manifests/fargate-deployment.yaml
```

``` sh
kubectl get pod -o wide
```

``` sh
kubectl delete -f $DIR/k8s-manifests/fargate-deployment.yaml
```

### Dynamic Volume Provisioning (EBS)

``` sh
kubectl apply -f $DIR/k8s-manifests/dvp-ebs.yaml
```

``` sh
kubectl get pod
kubectl get pvc
kubectl get pv
```

``` sh
kubectl delete -f $DIR/k8s-manifests/dvp-ebs.yaml
```

## 削除

``` sh
eksctl delete cluster -f sample-cluster.yaml
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
  - [ ] また、fargateのワーカーも用意する
    - [ ] fargateはdefaultのnamespaceに紐づく
    - [ ] fargateには`faragete: true`のラベルがついているPodだけ起動する 
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