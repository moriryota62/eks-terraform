
EKSでよく使う機能について、ユースケースごとに解説します。

# 事前準備

[使い方](./howtouse.md)から続けて作業している場合は環境変数を設定済のため事前準備は不要です。
環境変数を設定していない場合は以下の手順で環境変数を設定してください。

作業用ディレクトリを環境変数に設定します。

``` sh
cd <eks-terraformのルートディレクトリ>
export DIR=`pwd`
```

以降の手順で複数のファイルで使用する基本設定値を環境変数に設定しておきます。

``` sh
export REGION=us-east-2
export PJ=pj
export ENV=env
export OWNER=owner
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
Podを定義した内容と一致するnamespaceおよびラベルを指定して作成すると、そのPodはFargateにスケジュールされます。

サンプルで用意したTerraformのFargateプロファイルでは「Namespace：`default`」、「`worker: fargate`ラベル」のポッドセレクタを定義しています。
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

Podが起動したことを確認します。`-o wide`オプションをつけて起動先のノードがFargateであることをも確認します。
なお、FaragateでPodを起動するのはEC2ワーカーノードで起動するよりも少し時間がかかり、2分ほどかかります。
`Pending`->`ContainerCreating`->`Running`と状態が推移していき、`Running`になれば起動完了です。

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
代表的な方法として`EFS CSI Driver`を使用する方法と`EFS Provisioner`を使用する方法を紹介します。
両方の方法を同時に採用することもできます。

`EFS CSI Driver`は新たに開発されたものでいずれはこちらの方法がスタンダードになると思われます。
しかし、2020/11時点ではまだ開発中であり、Dynamic Volume Provisoning（以下、DVP）に対応していません。
そのため、用途ごとに領域を確保したい場合、手動でアクセスポイントを作成し、PersistentVolumeをapplyする手間が必要です。
一方、Fargateで起動しているPodに対してもボリューム提供できる点は`EFS Provisioner`にはない利点です。

`EFS Provisioner`は上記`EFS CSI Driver`のような手間はいりません。
ですが、Fargateで起動しているPodにはボリューム提供ができません。
一方、DVPが可能な点は`EFS CSI Driver`にはない利点です。

## EFS CSI Driverを使用する場合

[EFS CSI Driver](https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/efs-csi.html)

EFS CSI Driverを使用してEFSをマウントします。
FaragateのPodでEFSを使用するならEFS CSI Driverを使用します。

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

``` sh
kubectl apply -f efs-csi-sc.yaml
```

デプロイすると`PROVISIONERがefs.csi.aws.com`のStorageClassが追加されるので確認します。

``` sh
kubectl get storageclass
```

表示例

```
NAME            PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
efs-sc          efs.csi.aws.com         Delete          Immediate              false                  7s
gp2 (default)   kubernetes.io/aws-ebs   Delete          WaitForFirstConsumer   false                  10m
```

以上でEFS CSI Driverの準備は完了です。
テスト用のマニフェストを使用し、EFSのマウントができるか確認します。
テスト用のマニフェストを配置しているディレクトリに移動します。

``` sh
cd $DIR/manifests/efs-csi-driver/test
```

次に実際にEFS CSI Driverを使用してEFSをマウントする`Deployment`、`PersistentVolumeClaim`、`PersistentVolume`をデプロイします。
EFS CSI DriverはまだDVPに対応していないため、あらかじめPersistentVolumeを手動で作成します。

PersistentVolumeのマニフェストはEFSのファイルシステムIDを指定するため、自身の環境にあわせて修正する必要があります。
また、EFS CSI DriverでEFSをマウントするとEFSの/をマウントしてしまいます。
複数用途でひとつのEFSを利用する場合、EFSアクセスポイントで用途ごとのアクセスポイントを作成するのがよいです。
サンプルで用意したTerraformでは/test1と/test2のアクセスポイントを作成します。
PersistenVolumeのマニフェストのvolumeHandleに`<EFS ID>::<アクセスポイントID>`という形式で指定します。（Terraform実行後のoutputに表示される`access_points`はこの形式で出力しています）

`efs-csi-pv-1.yaml`および`efs-csi-pv-2.yaml`を自身の環境にあわせて修正してください。

``` sh
vi efs-csi-pv-1.yaml
vi efs-csi-pv-2.yaml
```

修正例

``` yaml
~略~
  csi:
    driver: efs.csi.aws.com
    volumeHandle: fs-a0076cd8::fsap-0fa1ab4ffc5f4a92f # この部分
```

修正したら以下コマンドでデプロイします。FargateなのでPod起動には少し時間がかかります。
2分ほど時間をおいてからget podしてください。
もし、pendingのままの場合はkubectl describe pod <pod名>を確認してください。
「Pod provisioning timed out」している場合はkubectl delete pod <pod名>でpodを再作成すると良いかもしれません。

``` sh
kubectl apply -f efs-csi-pv-1.yaml -f efs-csi-pv-2.yaml
kubectl apply -f efs-csi-pvc-1.yaml -f efs-csi-pvc-2.yaml
kubectl apply -f efs-csi-mount-deployment-1.yaml -f efs-csi-mount-deployment-2.yaml
kubectl get pod
```

表示例

```
NAME                               READY   STATUS    RESTARTS   AGE
efs-mount-csi-1-6c4c8b5669-4cdfc   1/1     Running   0          6m
efs-mount-csi-2-5876f5bbbd-m8kls   1/1     Running   0          2m19s
```

それぞれEFSでマウントしている領域に書き込みします。
以下はコマンド例です。Pod名は自身の環境にあわせて修正してください。

``` sh
kubectl exec efs-mount-csi-1-6c4c8b5669-4cdfc touch /test1/efs-test-1
kubectl exec efs-mount-csi-2-5876f5bbbd-m8kls touch /test2/efs-test-2
```

Podを削除します。
以下はコマンド例です。Pod名は自身の環境にあわせて修正してください。

``` sh
kubectl delete pod efs-mount-csi-1-6c4c8b5669-4cdfc
kubectl delete pod efs-mount-csi-2-5876f5bbbd-m8kls
```

しばらくしてからPodがセルフヒーリングされていることを確認します。

``` sh
kubectl get pod
```

表示例

```
NAME                               READY   STATUS    RESTARTS   AGE
efs-mount-csi-1-6c4c8b5669-smfqh   1/1     Running   0          99s
efs-mount-csi-2-5876f5bbbd-ww7vj   1/1     Running   0          95s
```

セルフヒーリング後のPodを確認し、ボリュームが永続化できていることを確認します。
以下はコマンド例です。Pod名は自身の環境にあわせて修正してください。

``` sh
kubectl exec efs-mount-csi-1-6c4c8b5669-smfqh ls /test1/
kubectl exec efs-mount-csi-2-5876f5bbbd-ww7vj ls /test2/
```

また、以下のようにPodをスケールさせます。

``` sh
kubectl scale deployment efs-mount-csi-1 --replicas=3
```

Podがスケールされていることを確認します。

``` sh
kubectl get pod
```

表示例

```
NAME                               READY   STATUS    RESTARTS   AGE
efs-mount-csi-1-6c4c8b5669-d4ddj   1/1     Running   0          5m22s
efs-mount-csi-1-6c4c8b5669-jqvpw   1/1     Running   0          5m22s
efs-mount-csi-1-6c4c8b5669-smfqh   1/1     Running   0          8m17s
efs-mount-csi-2-5876f5bbbd-ww7vj   1/1     Running   0          8m13s
```

`efs-mount-1`のさきほど確認したのとは違うPodを指定してボリュームが共有できていることを確認します。
以下はコマンド例です。Pod名は自身の環境にあわせて修正してください。

``` sh
kubectl exec efs-mount-csi-1-6c4c8b5669-d4ddj ls /test1/
```

以上で確認は終わりです。
テスト用のリソースをすべて削除します。
なお、これで削除するのはK8sリソースのみです。
EFSに保存したefs-test-1やefs-test-2はEFS内に残っているので注意ください。

``` sh
kubectl delete -f ./
cd ../
# EFS CSI Driverを引き続き使用する場合は以下コマンドは実施しなくてよいです。
kubectl delete -f efs-csi-sc.yaml
kubectl delete -k "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/ecr/?ref=release-1.0"
```

## EFS Provisionerを使用する場合

[EFS Provisioner](https://github.com/kubernetes-retired/external-storage/tree/master/aws/efs)を導入します。

EFS Provisionerのマニフェストは上記公式のレポジトリにありますが、以下ディレクトリにも配置しています。
なお、公式のマニフェストはDeploymentのapiVersionが`extensions/v1beta1`になっているなどK8s v1.15まででしか使えない記述があります。
以下ディレクトリに配置しているマニフェストはK8s v1.18でも動作するように修正してあります。
また、EFS Provisioner関連のK8sリソースはNamespaces:`efs-provisioner`に作成するようにも修正しています。

``` sh
cd $DIR/manifests/efs-provisioner
```

`manifest.yaml`に含まれる`yourEFSsystemid`と`yourEFSregion`を修正します。
`yourEFSsystemid`はterraform実行後に表示される`efs_id`の値を使います。
以下は修正するコマンド例です。

**Linuxの場合**

``` sh
sed -i -e 's:yourEFSregion:'$REGION':g' manifest.yaml
sed -i -e 's:yourEFSsystemid:fs-d05b35a8:g' manifest.yaml
```

**macの場合**

``` sh
sed -i "" -e 's:yourEFSregion:'$REGION':g' manifest.yaml
sed -i "" -e 's:yourEFSsystemid:fs-d05b35a8:g' manifest.yaml
```

まずEFS ProvisionerをデプロイするNamespace:`efs-provisioner`を作ります。

``` sh
kubectl apply -f ns.yaml
```

続いて、EFS Provisionerをデプロイします。

``` sh
kubectl apply -f rbac.yaml -f manifest.yaml
```

EFS Provisionerが作成できたことを確認します。以下の様にPodがRunningになっていれば良いです。

``` sh
kubectl get pod -n efs-provisioner
```

表示例

```
NAME                              READY   STATUS    RESTARTS   AGE
efs-provisioner-bc5dc9c84-pvdcm   1/1     Running   0          67s
```

また、StorageClassを確認し、`aws-efs`があることを確認します。

``` sh
kubectl get storageclass
```

表示例

```
NAME            PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
aws-efs         example.com/aws-efs     Delete          Immediate              false                  3m49s
gp2 (default)   kubernetes.io/aws-ebs   Delete          WaitForFirstConsumer   false                  56m
```

以上でEFS Provisionerの準備は完了です。
テスト用のマニフェストを使用し、EFSのマウントができるか確認します。
テスト用のマニフェストを配置しているディレクトリに移動します。

``` sh
cd $DIR/manifests/efs-provisioner/test
```

`efs-mount-1`と`efs-mount-2`の2つのDeploymentとPersistentVolumeClaimを用意しています。
Deploymentでは/test1または/test2にEFSをマウントする様に記述しています。
以下コマンドでapplyします。

``` sh
kubectl apply -f ./
```

デプロイできたか確認します。どちらもRunningになれば良いです。

``` sh
kubectl get pod
```

表示例

```
NAME                           READY   STATUS    RESTARTS   AGE
efs-mount-1-5dfcc844dc-xtml9   1/1     Running   0          32s
efs-mount-2-7c5ff5487b-5pkz5   1/1     Running   0          31s
```

それぞれEFSでマウントしている領域に書き込みします。
以下はコマンド例です。Pod名は自身の環境にあわせて修正してください。

``` sh
kubectl exec efs-mount-1-5dfcc844dc-xtml9 touch /test1/efs-test-1
kubectl exec efs-mount-2-7c5ff5487b-5pkz5 touch /test2/efs-test-2
```

Podを削除します。
以下はコマンド例です。Pod名は自身の環境にあわせて修正してください。

``` sh
kubectl delete pod efs-mount-1-5dfcc844dc-xtml9
kubectl delete pod efs-mount-2-7c5ff5487b-5pkz5
```

しばらくしてからPodがセルフヒーリングされていることを確認します。

``` sh
kubectl get pod
```

表示例

```
NAME                           READY   STATUS    RESTARTS   AGE
efs-mount-1-5dfcc844dc-pn2bf   1/1     Running   0          39s
efs-mount-2-7c5ff5487b-dnbqc   1/1     Running   0          24s
```

セルフヒーリング後のPodを確認し、ボリュームが永続化できていることを確認します。
以下はコマンド例です。Pod名は自身の環境にあわせて修正してください。

``` sh
kubectl exec efs-mount-1-5dfcc844dc-pn2bf ls /test1/
kubectl exec efs-mount-2-7c5ff5487b-dnbqc ls /test2/
```

また、以下のようにPodをスケールさせます。

``` sh
kubectl scale deployment efs-mount-1 --replicas=3
```

Podがスケールされていることを確認します。

``` sh
kubectl get pod
```

表示例

```
NAME                           READY   STATUS    RESTARTS   AGE
efs-mount-1-5dfcc844dc-jbwhf   1/1     Running   0          39s
efs-mount-1-5dfcc844dc-pn2bf   1/1     Running   0          4m19s
efs-mount-1-5dfcc844dc-wfr6g   1/1     Running   0          39s
efs-mount-2-7c5ff5487b-dnbqc   1/1     Running   0          4m4s
```

`efs-mount-1`のさきほど確認したのとは違うPodを指定してボリュームが共有できていることを確認します。
以下はコマンド例です。Pod名は自身の環境にあわせて修正してください。

``` sh
kubectl exec efs-mount-1-5dfcc844dc-jbwhf ls /test1/
```

以上で確認は終わりです。
テスト用のリソースをすべて削除します。
なお、これで削除するのはK8sリソースのみです。
EFSに保存したefs-test-1やefs-test-2はEFS内に残っているので注意ください。

``` sh
kubectl delete -f ./
cd ../
# EFS Provisionerを引き続き使用する場合は以下コマンドは実施しなくてよいです。
kubectl delete -f ./
```

# Ingress公開

IngressはK8s内のL7ロードバランサのようなものです。
K8s内に作成したサービス（アプリケーション）をK8s外へ公開する際によく使います。
ホストベースのルーティングをIngressを使用して実装します。

IngressはIngressの動作をコントロールする`Ingress Controller`とK8s内のリソースである`Ingress`の2つで成り立ちます。
`Ingress Controller`にはいくつか種類があります。[こちら](https://kubernetes.io/ja/docs/concepts/services-networking/ingress-controllers/)を参照ください。
EKSの場合、`NGINX Ingress Controller`か`AWS Load Balancer Controller`のいずれかが良いでしょう。
本手順ではこの2つの導入方法について解説します。

[NGINX Ingress Controller](https://kubernetes.io/ja/docs/concepts/services-networking/ingress-controllers/)は古くからあるIngress ControllerでAWS以外のクラウドでも同じように使うことのできるコントローラです。K8s内にControllerのPodとService type:LBでAWSにELBをデプロイし連携させることで動作します。`AWS Load Balancer Controller`よりも歴史が古いため、世の中のナレッジも豊富です。

[AWS Load Balancer Controller](https://github.com/kubernetes-sigs/aws-load-balancer-controller)はAWSのALBを使用したIngress Controllerです。以前は`ALB Ingress Controller`と呼ばれていましたが2020年10月に後継となる`AWS Load Balancer Controller`がリリースされました。K8s内にControllerのPodをデプロイします。FargateのPodにもルーティングできます。ELBはK8sのServiceとして管理するのではなく、`AWS Load Balancer Controller`が管理します。利用者はIngressリソースをデプロイする際にIngressGroupを指定します。

なお、サンプルのTerraformではRoute53関連のモジュールを用意しています。
もし特定のドメイン名でアクセスしたい場合はご活用ください。
サンプルでは`eks-test`という名前のVPCローカルなホストゾーンを作成しています。
続いてワイルドカードレコードを追加が、必要ですがレコード指定にIngress ControllerでデプロイされるLBのエイリアスを指定するため、Ingress Controllerデプロイ後に作成してください。

## NGINX Ingressを使用する場合

Ingress Controllerに[NGINX Ingress Controller](https://kubernetes.io/ja/docs/concepts/services-networking/ingress-controllers/)を使用します。

NGINX Ingress関連のマニフェストを配置したディレクトリに移動します。

``` sh
cd $DIR/manifests/nginx-ingress
```

配置してある`deploy.yaml`をapplyします。

``` sh
kubectl apply -f deploy.yaml
```

以下コマンドでNGINX Ingress Controllerがデプロイされていることを確認します。

``` sh
kubectl get pod -n ingress-nginx
```

表示例

```
NAME                                       READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-create-xzft5       0/1     Completed   0          6m16s
ingress-nginx-admission-patch-9cp6r        0/1     Completed   0          6m15s
ingress-nginx-controller-ddf87ddc8-mrtqq   1/1     Running     0          6m20s
```

また、Serviceもデプロイされていることを確認します。

``` sh
kubectl get svc -n ingress-nginx
```

表示例。
Type:LoadBalancerのServiceがデプロイされていることを確認します。
また、EXTERNAL-IPを控えて起きます。
Route53のレコード作成に使用します。

``` 
NAME                                 TYPE           CLUSTER-IP       EXTERNAL-IP                                                                     PORT(S)                      AGE
ingress-nginx-controller             LoadBalancer   172.20.1.67      a97ed4bfe1eea425fa26f445f2c76927-f72262769e8aa441.elb.us-east-2.amazonaws.com   80:30003/TCP,443:31777/TCP   7m44s
ingress-nginx-controller-admission   ClusterIP      172.20.226.229   <none>                                                                          443/TCP                      7m45s
```

以下コマンドでAWSにNLBが作成されていることも確認しておきましょう。また、CanonicalHostedZoneIdも確認します。

``` sh
aws elbv2 describe-load-balancers --region $REGION 
```

表示例。環境によってはもっとたくさんのLBが表示されるかもしません。
get svcで表示されたEXTERNAL-IPと同じDNSNameのLBがあるはずです。
また、CanonicalHostedZoneIdを控えておきます。
Route53のレコード作成に使用します。

```
{
    "LoadBalancers": [
        {
            "LoadBalancerArn": "arn:aws:elasticloadbalancing:us-east-2:456247443832:loadbalancer/net/a97ed4bfe1eea425fa26f445f2c76927/f72262769e8aa441",
            "DNSName": "a97ed4bfe1eea425fa26f445f2c76927-f72262769e8aa441.elb.us-east-2.amazonaws.com",
            "CanonicalHostedZoneId": "ZLMOA37VPKANP",
            "CreatedTime": "2020-12-06T10:46:39.539000+00:00",
            "LoadBalancerName": "a97ed4bfe1eea425fa26f445f2c76927",
            "Scheme": "internet-facing",
            "VpcId": "vpc-0339f07e684951883",
            "State": {
                "Code": "active"
            },
            "Type": "network",
            "AvailabilityZones": [
                {
                    "ZoneName": "us-east-2c",
                    "SubnetId": "subnet-04ebde1bfc22bbc54",
                    "LoadBalancerAddresses": []
                },
                {
                    "ZoneName": "us-east-2b",
                    "SubnetId": "subnet-0c69f8a86006e08e9",
                    "LoadBalancerAddresses": []
                }
            ],
            "IpAddressType": "ipv4"
        }
    ]
}
```

これでNGINX Ingress Controllerがデプロイできました。

続いて、Route53にワイルドカードレコードを追加します。
`*.eks-test`へのアクセスはすべて上記で確認したNLBに名前解決されるように登録します。
terraformのディレクトリへ移動します。

``` sh
cd $DIR/terraform/main
```

`local_values.tf`のroute53 module関連パラメータにある`recods`を設定します。
`recods`の`name`には登録したいレコード（*.eks-test）を指定します。
`elb_name`にはService Type:LoadBalancerデプロイ後に確認した**EXTERNAL-IP**を指定します。
`elb_zone_id`にはService Type:LoadBalancerデプロイ後に確認した**CanonicalHostedZoneId**を指定します。
**ホストゾーンのIDではない**ため注意してください。

``` sh
vi local_values.tf
```

修正したらterraformでレコードを作成します。

``` sh
terraform apply 
> yes
```

以上でIngressを使うための準備が整いました。
実際にサンプルのマニフェストを使用してIngressの動作を確認します。

サンプルマニフェストを配置してディレクトリに移動してください。

``` sh
cd $DIR/manifests/nginx-ingress/test
```

サンプルマニフェストをapplyします。
このサンプルマニフェストはnic-ingress-1および2という名前のPodを作成します。
またIngressは`nic-ingress-1.eks-test`および`nic-ingress-2.eks-test`で公開しています。
これらのホストでアクセスするとELBを経由し、Ingress Controllerへ届き、Ingress Controllerが宛先のホストを判断して然るべきServiceへトラフィックを流します。

``` sh
kubectl apply -f ./
```

サンプルマニフェストで作成したリソースを確認します。

``` sh
kubectl get pod,svc,ingress
```

nic-ingress-1および2という名前のPod、Service、Ingressができるていることを確認します。

```
NAME                                 READY   STATUS    RESTARTS   AGE
pod/nic-ingress-1-59fb6644fc-dbpkf   1/1     Running   0          16m
pod/nic-ingress-2-7b847f6797-dkz9r   1/1     Running   0          16m

NAME                    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/kubernetes      ClusterIP   172.20.0.1      <none>        443/TCP   65m
service/nic-ingress-1   ClusterIP   172.20.95.99    <none>        80/TCP    16m
service/nic-ingress-2   ClusterIP   172.20.225.97   <none>        80/TCP    16m

NAME                               CLASS    HOSTS                    ADDRESS                                                                         PORTS   AGE
ingress.extensions/nic-ingress-1   <none>   nic-ingress-1.eks-test   a9674b1a36c76457fbd81f1c3144c713-4a38fa0797d50e60.elb.us-east-2.amazonaws.com   80      8m17s
ingress.extensions/nic-ingress-2   <none>   nic-ingress-2.eks-test   a9674b1a36c76457fbd81f1c3144c713-4a38fa0797d50e60.elb.us-east-2.amazonaws.com   80      8m16s
```

実際にIngressでルーティングされるか確認します。
`*.eks-test`はVPC内でのみ使える名前です。
そのため、踏み台サーバなどEKSと同じVPCに属するEC2インスタンスへログインし、以下のコマンドを実行します。

``` sh
curl nic-ingress-1.eks-test
```

以下の様に`nic-ingress-1`へ到達できていることが確認できます。

```
nic-ingress-1
```

続いて`nic-ingress-2.eks-test`へcurlします。

``` sh
curl nic-ingress-2.eks-test
```

以下の様に`nic-ingress-2`へ到達できていることが確認できます。

```
nic-ingress-2
```

以上のようにIngressを使いホストベースのルーティングが行えました。
NGINX Ingress Controllerの場合、公開用のELBをIngress Controller用の1つに抑えることができます。

サンプル用のリソースを削除します。

``` sh
kubectl delete -f ./
```

Ingress Controllerも不要であれば以下コマンドで削除します。

``` sh
cd ../
kubectl delete -f deploy.yaml
```

## AWS Load Balancer Controllerを使用する場合

[AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/)をデプロイします。
AWS Load Balancer Controller(以下、ALB Controller)はコントローラとなるPodをK8s内にデプロイします。
そのコントローラPodがK8s内のIngressリソースを監視し、Ingressリソースが作成されるとELBのリスナーなどを作成します。
そのため、このコントローラPodからAWSのELBを操作するIAMの権限が必要となります。
本レポジトリのterraformではALB Controllerが必要とするIAMポリシーをIAM for SAでK8s内にあるServiceAccountと紐付けるサンプルを用意しています。また、以下デプロイ手順は次の[AWSドキュメント](https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/alb-ingress.html)をベースに作成しています。

IAM for SAで紐付けるIAMロールの存在を確認します。もし、本レポジトリのterraform以外でIAMロールを作成している場合は、自身の環境にあわせてロール名を修正してください。

``` sh
aws iam get-role --role-name=$PJ-$ENV-SAIAM-kube-system-aws-load-balancer-controller
```

以下のようにIAMロールが表示されればIAMロールが作成されています。

``` json
{
    "Role": {
        "Path": "/",
        "RoleName": "PJ-ENV-SAIAM-kube-system-aws-load-balancer-controller",
~略~
```

ALB Controllerが使用するカスタムリソース`TargetGroupBinding`を以下コマンドでデプロイします。

``` sh
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"
```

以下コマンドで確認します。見慣れないリソースですが、これはALB Controller用に作成したカスタムリソースです。

``` sh
kubectl get targetgroupbindings
```

以下のように出力されれば問題ないです。カスタムリソースがちゃんと作成できていない場合は`error: the server doesn't have a resource type "targetgroupbindings"`と表示されます。

```
No resources found in default namespace.
```

[helm](https://helm.sh/ja/)を使用してALB Controllerをデプロイします。
helm自体はbrew等のパッケージマネージャでインストール可能です。
helmのインストールについて詳しくは[こちら](https://helm.sh/docs/intro/install/)のドキュメントを参照ください。
以下コマンドでデプロイします。
以下コマンドではNamespace:kube-systemにデプロイします。
また、ServiceAccount:aws-load-balancer-controllerも同時に作成します。

``` sh
helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller \
  --set clusterName=$PJ-$ENV \
  --set serviceAccount.create=yes \
  --set serviceAccount.name=aws-load-balancer-controller \
  -n kube-system
```

以下コマンドで作成確認します。

``` sh
kubectl get pod -n kube-system
```

以下のように`aws-load-balancer-controller-XXXXX`のPodがRunningになっていれば良いです。

```
NAME                                            READY   STATUS    RESTARTS   AGE
aws-load-balancer-controller-864c98f8f5-kx7rw   1/1     Running   0          26s
```

しかし、このままではまだPod(ServiceAccount)にIAMロールが付与されていません。
以下のコマンドでServiceAccount:`aws-load-balancer-controller`を編集します。

``` sh
kubectl edit sa -n kube-system aws-load-balancer-controller
```

以下のように、metadata.annotationsに`eks.amazonaws.com/role-arn: <IAMロールARN>`を設定してください。
以下は編集例です。アカウントIDとPJ-ENVは自身の環境に合わせてください。
kubectl editの操作はviエディタと同じです。
なお、この手順ではeditで直接マニフェストを書き換えていますが、本来ならIaCとしてマニフェストに残すべきです。
すでにデプロイ済のリソースをマニフェストに出力するには`kubectl get <リソース種別> <リソース名> -o yaml`でマニフェストを出力し、ファイルに保存すると良いでしょう。

```
metadata:
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::456247443832:role/pj-env-SAIAM-kube-system-aws-load-balancer-controller
```

上記設定したら一度Podを再作成します。
Pod名はさきほど確認したALB Controller Podの名前に置き換えてください。

``` sh
kubectl delete pod -n kube-system <aws-load-balancer-controller-XXXXX>
```

セルフ・ヒーリングによりPodが再作成されRunningしていることを確認します。

``` sh
kubectl get pod -n kube-system
```

表示例

```
NAME                                            READY   STATUS    RESTARTS   AGE
aws-load-balancer-controller-864c98f8f5-vscn8   1/1     Running   0          27s
```

以上でALB Controllerのデプロイは完了です。

続いて、ALB COntrollerの動作を確認するため、Ingressリソースと簡単なNginxのWebサーバーをデプロイしてみます。
まずは動作確認用のサンプルマニフェストを配置しているディレクトリに移動します。

``` sh
cd $DIR/manifests/alb-ingress/test
```

配置してあるマニフェスト一式をデプロイします。
簡単にマニフェストを解説すると以下の通りです。

- Nginxを動かす`alb-ingress-1`および`2`のDeployment
  - 各Podは`localhost/alb-ingress-1/test/`(2の場合はingress-2)にアクセスすると固有のメッセージを返す
- 上記Deploymentは`alb-ingress-1`および`2`のServiceで待ち受けている
- 外部へ公開するための`alb-ingress-1`および`2`のIngress
  - 各IngressはALB Controllerを使用するannotationsをつけている
  - ターゲットグループはどちらも`test`(同じターゲットグループだとLBを共有する)
  - `<LB DNS>/alb-ingress-1`および`2`のアクセスが着た場合、対応する名前のServiceへ流す

``` sh
kubectl apply -f ./
```

デプロイを確認します。

``` sh
kubectl get pod
```

以下のように`alb-ingress-1-XXXX`および`alb-ingress-2-XXXX`がRunningになっていればよいです。

```
NAME                             READY   STATUS    RESTARTS   AGE
alb-ingress-1-6788f547cc-dzjwb   1/1     Running   0          6m33s
alb-ingress-2-cc7f48-ffdcz       1/1     Running   0          6m33s
```

また、Ingressリソースも確認しておきます。

``` sh
kubectl get ingress
```

以下のようにIngressリソースが作成され、ADDRESSにALBのパブリックDNS名が表示されていれば良いです。
今回のサンプルでは同じターゲットグループを指定しているためADDRESSも同じになっています。

```
NAME            CLASS    HOSTS   ADDRESS                                                      PORTS   AGE
alb-ingress-1   <none>   *       k8s-test-83a2f4c943-1229419113.us-east-2.elb.amazonaws.com   80      20s
alb-ingress-2   <none>   *       k8s-test-83a2f4c943-1229419113.us-east-2.elb.amazonaws.com   80      20s
```

作業端末のWebブラウザ等で以下のアドレスにアクセスします。
ALB Controllerを経由し、パスに応じて適切なPodへ接続できることを確認します。

- http://k8s-test-83a2f4c943-1229419113.us-east-2.elb.amazonaws.com/alb-ingress-1/
- http://k8s-test-83a2f4c943-1229419113.us-east-2.elb.amazonaws.com/alb-ingress-2/

以上で動作の確認は完了です。
テスト用のリソースは以下コマンドで削除します。

``` sh
cd $DIR/manifests/alb-ingress/test
kubectl delete -f ./
```

ALB Controllerも不要な場合は以下コマンドで削除します。

``` sh
helm uninstall aws-load-balancer-controller -n kube-system
kubectl delete -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"
```

# IAM Role for SAによるPodへのIAMロール付与

# Metrics Serverの導入

# Cluster AutoScallerによるワーカーノードのオートスケール

# Horizontal Pod AutoScallerによるPod数のオートスケール

