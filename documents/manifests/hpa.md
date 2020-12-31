# Horizontal Pod Autoscaler

Horizontal Pod Autoscaler（通称、HPA）はPodのメトリクス状況に応じてPodコントローラのreplica数を自動で調整するK8s標準に組み込まれた機能です。
HPAを使用することで負荷状況に合わせた運用を自動化する事ができます。
HPAはK8sの標準リソースで定義しますが、HPAの機能を使用するにはメトリクス収集をする仕組みが必要となります。
EKSの場合このメトリクスを収集する仕組みは利用者でデプロイする必要があります。
この仕組でもっとも基本的なものはmetrics serverです。
HPAは標準ではCPU使用率のメトリクスのみ使用してPodをスケールします。
CPU使用率以外のメトリクスでPodをスケールさせたい場合、カスタムメトリクスを定義する必要があります。

HPAについてのK8s公式ドキュメントは[こちら](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)です。EK公式ドキュメントは[こちら](https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/horizontal-pod-autoscaler.html)です。

HPAを定義する前にメトリクスを収集する仕組みがクラスタにデプロイ済か確認します。
たとえばmetrics serverがあるかは以下コマンドで確認します。

``` sh
kubectl get pod -n kube-system
```

以下のように`metris-server-XXXXXX`が表示されれば良いです。

```
NAME                              READY   STATUS    RESTARTS   AGE
metrics-server-5f956b6d5f-glwlf   1/1     Running   0          27h
```

HPAのサンプルマニフェストを配置したディレクトリに移動します。

``` sh
cd $DIR/manifests/hpa
```

マニフェストをapplyします。
以下に簡単にapplyするマニフェストについて解説します。
- HPAのターゲットとなるnginxのdeployment。CPU0.1コアをリソース要求に設定（HPAを使用したい場合、リソース要求量指定は必須です。）
- HAPターゲットのservice
- ターゲットのHPA設定。目標CPU使用率の平均を30%に設定し1~3の間でPod数を変化させる
- 負荷コマンド実行用のPodをデプロイするdeployment

``` sh
kubectl apply -f ./
```

``` sh
kubectl get pod
```

以下のように`source-XXXX`と`target-XXXX`が表示されれば良いです。

```
NAME                      READY   STATUS    RESTARTS   AGE
source-f6d667c96-llhkr    1/1     Running   0          12m
target-548c65d58f-qpz6g   1/1     Running   0          12m
```

`source-XXXX`のPodからtargetに対して負荷を発生させます。
以下コマンドを実行してください。
Pod名は環境に合わせて修正してください。
下記コマンドはしばらく実行したままにしたいため、もう1つプロンプトを開きます。（コマンドが終わるまで待っても良いです。）

```
kubectl exec source-f6d667c96-llhkr -- /bin/bash -c "ab -n 1000000 -c 100 http://target/"
```

以下コマンドを実行し、targetのPod数がスケールされていることを確認します。（新しいプロンプトの場合、kubeconfigなど環境変数の設定を忘れずに！）

``` sh
kubectl get pod
```

以下のように`target-XXXX`のPod数が3にスケールアウトしているはずです。

```
NAME                      READY   STATUS    RESTARTS   AGE
source-f6d667c96-llhkr    1/1     Running   0          17m
target-548c65d58f-47wvf   1/1     Running   0          3m5s
target-548c65d58f-qpz6g   1/1     Running   0          17m
target-548c65d58f-rknb5   1/1     Running   0          3m4s
```

しばらく（5~10分）時間が経てば今度はPod数が1に自動でスケールインします。

``` sh
kubectl get pod
```

```
NAME                      READY   STATUS    RESTARTS   AGE
source-f6d667c96-llhkr    1/1     Running   0          22m
target-548c65d58f-qpz6g   1/1     Running   0          22m
```

以上でHPAの動作確認は終わりです。
サンプルのリソースを削除します。

``` sh
cd $DIR/manifests/hpa
kubectl delete -f ./
```