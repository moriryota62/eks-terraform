
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

[NGINX Ingress Controller](https://kubernetes.io/ja/docs/concepts/services-networking/ingress-controllers/)は古くからあるIngress ControllerでAWS以外のクラウドでも同じように使うことのできるコントローラです。K8s内にControllerのPodとService type:LBでAWSにELBをデプロイし連携させることで動作します。`複数のIngressで一つのELBを集約できる`のがメリットです。

[AWS Load Balancer Controller](https://github.com/kubernetes-sigs/aws-load-balancer-controller)はAWSのALBを使用したIngress Controllerです。以前は`ALB Ingress Controller`と呼ばれていましたが変わりました。K8s内にControllerのPodをデプロイします。`IngressごとにLBを作成するため集約できません。`

Ingressの前にAWSのRoute53にテスト用のプライベートホストゾーンとレコードを作成します。
この手順ではテスト用の一時的なものであるためコマンドで作成しますが、恒久的に使用するドメインの場合はTerraformで作成してください。
また、すでにドメイン取得済の場合はそのドメインを使用しても構いません。

まずは`eks-test`ホストゾーンを以下コマンドで作成します。
`VPCId`は自身の環境に合わせて指定ください。(vpcidはterraformのoutputにも表示されます。)
`caller-reference`は任意の文字列で良いので実行時の日付（YYYYMMDDhhmm）など好きな文字列を指定ください。

``` sh
aws route53 create-hosted-zone --name eks-test --vpc VPCRegion=$REGION,VPCId=<VPCID> --hosted-zone-config Comment=eks-test,PrivateZone=true --caller-reference <任意の文字列>
aws route53 create-hosted-zone --name eks-test --vpc VPCRegion=$REGION,VPCId=vpc-08c0631a2837a950a --hosted-zone-config Comment=eks-test,PrivateZone=true --caller-reference 202012071919
```

ホストゾーンができたことを確認します。

``` sh
aws route53 list-hosted-zones
```

表示例。環境によってはもっとたくさんのホストゾーンが表示されるかもしません。

```
{
    "HostedZones": [
        {
            "Id": "/hostedzone/Z07357812CRW9HLLUA1A4",
            "Name": "eks-test.",
            "CallerReference": "202012051924",
            "Config": {
                "Comment": "eks-test",
                "PrivateZone": true
            },
            "ResourceRecordSetCount": 2
        }
    ]
}
```

以上でホストゾーンの準備は終わりです。
続いてワイルドカードレコードを追加しますが、この手順はIngress Controller作成後に行います。

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
`recode.json`の`HostedZoneId`と`DNSName`を修正してください。
なお、`HostedZoneId`はService Type:LoadBalancerデプロイ後に確認した**CanonicalHostedZoneId**を指定します。
**ホストゾーンのIDではない**ため注意してください。
`DNSName`はService Type:LoadBalancerデプロイ後に確認した**EXTERNAL-IP**を指定します。
また、ホストゾーンが`eks-tset`でない場合は`Name`も修正してください。

``` sh
vi recode.json
```

修正例

``` json
{
    "Comment": "Creating Alias resource record sets in Route 53",
    "Changes": [{
               "Action": "CREATE",
               "ResourceRecordSet": {
                           "Name": "*.eks-test",#ドメインが違う場合はここも変える
                           "Type": "A",
                           "AliasTarget":{
                                   "HostedZoneId": "ZLMOA37VPKANP",#ここにCanonicalHostedZoneId
                                   "DNSName": "a9674b1a36c76457fbd81f1c3144c713-4a38fa0797d50e60.elb.us-east-2.amazonaws.com",#ここにEXTERNAL-IP
                                   "EvaluateTargetHealth": false
                             }}
                         }]
}
```

`recode.json`を修正したら以下のコマンドを実行します。`hosted-zone-id`は**ホストゾーンのIDを指定**します。
ロードバランサーのCanonicalHostedZoneIdではないため注意してください。

``` sh
aws route53 change-resource-record-sets --hosted-zone-id Z05116041JLKENQ1L8UPE --change-batch file://recode.json
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
cd ../
```

サンプル用のRoute53レコードも削除します。
削除する前に`recode.json`を修正します。
以下コマンドを実行ください。

**Linuxの場合**

``` sh
sed -i -e "s/CREATE/DELETE/g" recode.json
```

**macの場合**

``` sh
sed -i "" -e "s/CREATE/DELETE/g" recode.json
```

`recode.json`を修正したら以下コマンドでレコードを削除します。
Ingress Controllerやホストゾーンも不要であれば以下コマンドで削除します。

``` sh
aws route53 change-resource-record-sets --hosted-zone-id Z05116041JLKENQ1L8UPE --change-batch file://recode.json
kubectl delete -f deploy.yaml
aws route53 delete-hosted-zone --id Z05116041JLKENQ1L8UPE 
```

## AWS Load Balancer Controllerを使用する場合

# IAM Role for SAによるPodへのIAMロール付与

# Metrics Serverの導入

# Cluster AutoScallerによるワーカーノードのオートスケール

# Horizontal Pod AutoScallerによるPod数のオートスケール

