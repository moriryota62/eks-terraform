# Cluster Autoscaler

Cluster Autoscaler(通称CA)はK8sのクラスタノードを自動で調整する機能です。
クラスタにCAを動作させるPodをデプロイして動作します。
CAはAWSのAuto Scallingと連携して動作します。
Podスケジュール時にリソース不足によるPendingが発生するとノード数を自動で増やします。
ノード（Auto Scalling）側にはCAで操作できるようにタグを付与する必要があります。
CA側にはAuto Scallingを操作するためのIAM権限が必要になります。
本レポジトリのterraformでEKSを作成すれば上記必要なタグやIAMの権限は作成済のため手動で作成は不要です。

CAについてEKS公式のドキュメントは[こちら](https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/cluster-autoscaler.html)になります。

CAのマニフェストを配置しているディレクトリに移動します。

``` sh
cd $DIR/manifests/ca
```

マニフェスト内の<YOUR CLUSTER NAME>部分を自身のクラスター名に置換します。

**Linuxの場合**

``` sh
sed -i -e "s/<YOUR CLUSTER NAME>/$PJ-$ENV/" cluster-autoscaler-autodiscover.yaml
```

**Macの場合**

``` sh
sed -i "" -e "s/<YOUR CLUSTER NAME>/$PJ-$ENV/" cluster-autoscaler-autodiscover.yaml
```

CAをデプロイします。

``` sh
kubectl apply -f ./
```

デプロイできたか確認します。

``` sh
kubectl get pod -n kube-system
```

以下のように`cluster-autoscaler-XXXX`というPodがRunningしていれば良いです。

``` sh
NAME                                 READY   STATUS    RESTARTS   AGE
cluster-autoscaler-67b8ccccc-8dqpw   1/1     Running   0          40s
```

以上でCAのデプロイは完了です。
続いてCAの動作確認をします。
サンプルマニフェストを配置しているディレクトリに移動します。

``` sh
cd $DIR/manifests/ca/test
```

サンプルのマニフェストを解説すると以下の特徴があります。
- nginxのPod。レプリカ数は4。リソースのrequestsでCPUを1コア

CAを動作させるにはリソース量にrequestsが大事です。
本レポジトリのterraformではワーカーノードのインスタンスタイプをt3.medium（CPU2コア）で作成します。
ワーカーノードのkubeletが0.1コア程CPUを確保しているため、利用可能なCPUコア数は1ノード1.9コアです。
requests cpu 1の上記Podは1ノードに1つしか動かすことができません。
そのため、上記applyすることでCPUリソース不足のPending Podができます。
Pending PodができるとCAによりノード数が拡張されます。

サンプルマニフェストをデプロイする前にノードの状態を確認します。

``` sh
kubectl get node
```

以下のようにノード数が1になっているはずです。（本レポジトリのterraformのデフォルト）

```
NAME                                        STATUS   ROLES    AGE    VERSION
ip-10-1-20-71.us-east-2.compute.internal    Ready    <none>   4d3h   v1.18.9-eks-d1db3c
```

サンプルマニフェストをデプロイします。

``` sh
kubectl apply -f ./
```

Podのデプロイ状況を確認します。

``` sh
kubectl get pod
```

以下のように1つだけrunningでそれ以外がpendingになります。

```
NAME                       READY   STATUS    RESTARTS   AGE
ca-test-58cd877444-666x8   0/1     Pending   0          39s
ca-test-58cd877444-g7fjc   0/1     Pending   0          39s
ca-test-58cd877444-gxhr2   1/1     Running   0          39s
ca-test-58cd877444-pwwwt   0/1     Pending   0          39s
```

（しばらく時間が経ってから）ノードの数を確認します。

``` sh
kubectl get node
```

以下のようにノード数が3に増えているはずです。

```
NAME                                        STATUS   ROLES    AGE    VERSION
ip-10-1-20-71.us-east-2.compute.internal    Ready    <none>   4d3h   v1.18.9-eks-d1db3c
ip-10-1-21-143.us-east-2.compute.internal   Ready    <none>   57s    v1.18.9-eks-d1db3c
ip-10-1-21-93.us-east-2.compute.internal    Ready    <none>   58s    v1.18.9-eks-d1db3c
```

再度Podの状態を確認します。

``` sh
kubectl get pod
```

以下のようにrunnnigが3つ、pendingが1つになっているはずです。

```
NAME                       READY   STATUS    RESTARTS   AGE
ca-test-58cd877444-666x8   1/1     Running   0          3m2s
ca-test-58cd877444-g7fjc   0/1     Pending   0          3m2s
ca-test-58cd877444-gxhr2   1/1     Running   0          3m2s
ca-test-58cd877444-pwwwt   1/1     Running   0          3m2s
```

以上のようにpendingのPodが発生するとCAによりノードが自動でスケールアウトされました。

続いて自動でスケールインされる動作を確認します。
以下コマンドでPod数をスケールインさせます。

``` sh
kubectl scale deployment ca-test --replicas=1
```

以下コマンドでPodの状態とノード数を確認します。

``` sh
kubectl get pod,node
```

スケールインはスケールアウトよりも時間がかかります。
そのため、kubectl scaleコマンド実行直後は以下のようにPod数は減ってもノード数は変化していないはずです。
CAはデフォルトではスケールインまでの猶予期間を10分もうけているため、10分+数分程経過した後再度確認します。

**ノードスケールイン前**

```
NAME                           READY   STATUS    RESTARTS   AGE
pod/ca-test-58cd877444-gxhr2   1/1     Running   0          9m18s

NAME                                             STATUS   ROLES    AGE     VERSION
node/ip-10-1-20-71.us-east-2.compute.internal    Ready    <none>   4d4h    v1.18.9-eks-d1db3c
node/ip-10-1-21-143.us-east-2.compute.internal   Ready    <none>   8m58s   v1.18.9-eks-d1db3c
node/ip-10-1-21-93.us-east-2.compute.internal    Ready    <none>   8m59s   v1.18.9-eks-d1db3c
```

**ノードスケールイン後（10分経過後）**

```
NAME                           READY   STATUS    RESTARTS   AGE
pod/ca-test-58cd877444-gxhr2   1/1     Running   0          19m

NAME                                            STATUS                        ROLES    AGE    VERSION
node/ip-10-1-20-71.us-east-2.compute.internal   Ready                         <none>   4d4h   v1.18.9-eks-d1db3c
```

以上でCAの動作確認は完了です。
サンプルマニフェストを削除します。

``` sh
cd $DIR/manifests/ca/test
kubectl delete -f ./
```

CAも不要であれば以下コマンドで削除します。

``` sh
cd $DIR/manifests/ca
kubectl delete -f ./
```