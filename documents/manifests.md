
EKSでよく使う機能について、ユースケースごとに解説します。

# 事前準備

[使い方](./howtouse.md)から続けて作業している場合は環境変数を設定済のため事前準備は不要です。
環境変数を設定していない場合は以下の手順で環境変数を設定してください。

作業用ディレクトリを環境変数に設定します。

``` sh
cd <eks-terraformのルートディレクトリ>
export DIR=`pwd`
```

kubeconfigを設定していない場合は環境変数に設定します。

``` sh
export KUBECONFIG=<kubeconfigのパス>
```

以下コマンドでEKSとの接続を確認します。ノードが表示されれば接続できています。

``` sh
kubectl get node
```

# FargateでのPod起動

EKSではFargateでPodを起動することも可能です。
FargateでPodをするにはあらかじめEKSにFargateプロファイルを作成しておく必要があります。
Fargateプロファイルの作成はTerraformを活用ください。

Fargateプロファイルの中で`ポッドセレクタ`を指定します。
ポッドセレクタにはK8s内の`namespace`名と`ラベル`を定義します。
定義した内容と一致するnamespaceおよびラベルを指定したPodを作成すれば、PodはFargateにスケジュールされます。

サンプルで用意したTerraformでは「Namespace：`default`」、「`worker: fargate`ラベル」のポッドセレクタを定義しています。
上記ポッドセレクタの場合にFargateでPodを起動するサンプルマニフェストを用意しています。

サンプルマニフェストがあるディレクトリに移動します。

``` sh
cd $DIR/manifests/fargate
```

このディレクトリに`fargate-deployment.yaml`があります。
これはFargateでPodを起動するDeploymentのサンプルです。
Fargateプロファイルにあわせ、Namespaceは`default`を指定しています。（指定なしでもdefaultで起動しますが、今回はあえてわかりやすい様にNamespaceを指定しています。）
ラベルは`worker: fargate`を指定しています。


マニフェストをapplyします。

``` sh
kubectl apply -f ./fargate-deployment.yaml
```

Podが起動したことを確認します。なお、`-o wide`オプションをつけ、起動先のノードがFargateであることをも確認します。なお、FaragateでPodを起動するのはEC2ワーカーノードで起動するよりも少し時間がかかり、2分ほどかかります。`Pending`->`ContainerCreating`->`Running`と状態が推移しいき、`Running`になれば起動完了です。

``` sh
kubectl get pod -o wide
```

表示例

```
NAME                      READY   STATUS    RESTARTS   AGE     IP            NODE                                                NOMINATED NODE   READINESS GATES
fargate-5d9865d5c-j4gcb   1/1     Running   0          3m36s   10.1.20.160   fargate-ip-10-1-20-160.us-east-2.compute.internal   <none>           <none>
```

# EFSのマウント

## EFS Provisonerを使用する場合

## EFS CSI Driverを使用する場合

# Ingress公開

## Nginx Ingressを使用する場合

## ALB Ingressを使用する場合

# IAM Role for SAによるPodへのIAMロール付与

# Metrics Serverの導入

# Cluster AutoScallerによるワーカーノードのオートスケール

# Horizontal Pod AutoScallerによるPod数のオートスケール

