
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
これはFargateでPodを起動するDeploymentのサンプルです。
Fargateプロファイルにあわせ、Namespaceは`default`を指定しています。（指定なしでもdefaultで起動しますが、今回はあえてわかりやすい様にNamespaceを指定しています。）
ラベルは`worker: fargate`を指定しています。


マニフェストをapplyします。

``` sh
kubectl apply -f ./fargate-deployment.yaml
```

Podが起動したことを確認します。`-o wide`オプションをつけ起動先のノードがFargateであることをも確認します。
なお、FaragateでPodを起動するのはEC2ワーカーノードで起動するよりも少し時間がかかり、2分ほどかかります。
`Pending`->`ContainerCreating`->`Running`と状態が推移しいき、`Running`になれば起動完了です。

``` sh
kubectl get pod -o wide
```

表示例

```
NAME                      READY   STATUS    RESTARTS   AGE     IP            NODE                                                NOMINATED NODE   READINESS GATES
fargate-5d9865d5c-j4gcb   1/1     Running   0          3m36s   10.1.20.160   fargate-ip-10-1-20-160.us-east-2.compute.internal   <none>           <none>
```

# EFSのマウント

EKSでEFSを使用する方法はいくつかあります。
代表的な方法として`EFS Provisoner`を使用する方法と`EFS CSI Driver`を使用する方法を紹介します。

`EFS CSI Driver`は新たに開発されたものでいずれはこちらの方法がスタンダードになると思われます。
しかし、2020/11時点ではまだ開発中であり、Dynamic Volume Provisoning（以下、DVP）に対応していません。
そのため、用途ごとに領域を確保したい場合、手動でアクセスポイントを作成し、PersistentVolumeをapplyする手間が必要です。
一方、Fargateで起動しているPodに対してもボリューム提供できる点は`EFS Provisoner`にはない利点です。

`EFS Provisoner`は上記`EFS CSI Driver`のような手間はいりません。
ですが、Fargateで起動しているPodにはボリューム提供ができません。
一方、DVPが可能な点は`EFS CSI Driver`にはない利点です。

つまり、以下2点をポイントにどちらかの方法を選択します。

- DVP無しが許容できるか（運用の手間）
- Fargateでボリューム共有が必要なPodを動かすか

## EFS Provisonerを使用する場合

## EFS CSI Driverを使用する場合

現在、EFS CSI Driverが開発されています。
これを使えば今まではProvisoner Pod経由でEFSを使用していましたが、各Podが直接EFSをマウントできるようになります。
まだ開発段階のため、DVPには対応していませんが、将来的にはEFS ProvisonerではなくEFS CSI Driverが主流になると思われます。

EFS CSI Driver関連のマニフェストを配置したディレクトリに移動します。

``` sh
cd $DIR/manifests/efs-csi-driver
```

EFS CSI Driverは以下コマンドでデプロイします。2020/11現在は手動でデプロイする必要がありますが、将来的にはEKSに標準で組み込まれる予定です。

``` sh
kubectl apply -k "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/ecr/?ref=release-1.0"
```

EFS CSI Driverを指定した`StorageClass`をデプロイします。
`efs-csi-sc.yaml`をそのままapplyすれば良いです。
デプロイすると`PROVISIONERがefs.csi.aws.com`のStorageClassが追加されます。

``` sh
kubectl apply -f efs-csi-sc.yaml
kubectl get storageclass
```

次に実際にEFS CSI Driverを使用してEFSをマウントする`Deployment`、`PersistentVolumeClaim`、`PersistentVolume`をデプロイします。
EFS CSI DriverはまだDVPに対応していないため、あらかじめPersistentVolumeを手動で作成する必要があります。
また、PersistentVolumeのマニフェストはEFSのファイルシステムIDを指定するため、自身の環境にあわせて修正してください。

`efs-csi-pv.yaml`を自身の環境にあわせて修正したら以下コマンドでデプロイします。

``` sh
kubectl apply -f efs-csi-mount-deployment.yaml -f efs-csi-pvc.yaml -f efs-csi-pv.yaml
kubectl get pod
```



# Ingress公開

## Nginx Ingressを使用する場合

## ALB Ingressを使用する場合

# IAM Role for SAによるPodへのIAMロール付与

# Metrics Serverの導入

# Cluster AutoScallerによるワーカーノードのオートスケール

# Horizontal Pod AutoScallerによるPod数のオートスケール

