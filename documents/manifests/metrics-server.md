# Metrics Server

Metrics ServerをクラスタにデプロイするとNodeやPodの実使用CPU/メモリのメトリクス情報を収集できるようになります。
たとえば`kubectl top`や`Horizontal Pod Autoscaler(HPA)`を使用する場合に使います。

Metrics ServerはPodとして動かします。

Metrics Serverのマニフェストを配置したディレクトリに移動します。

``` sh
cd $DIR/manifests/metrics-server
```

以下コマンドでマニフェストをapplyします。
なお、配置してあるマニフェストは[EKSのドキュメント](https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/metrics-server.html)にあるマニフェストと同じものです。

``` sh
kubectl apply -f ./
```

デプロイできたことを確認します。

``` sh
kubectl get pod -n kube-system
```

以下のように`metrics-server-XXXXX`という名前のPodがRunningになっていれば良いです。

```
NAME                              READY   STATUS    RESTARTS   AGE
metrics-server-5f956b6d5f-glwlf   1/1     Running   0          25s
```

Metrics Serverをデプロイ後、`kubectl top`が使えるようになっていることを確認します。
デプロイ直後だとメトリクスが収取できていない場合もあるので、失敗する場合は少し時間をおいて再実行してください。

``` sh
kubectl top node
kubectl top pod -n kube-system
```

NodeやPodの現在のCPU/メモリの使用量が確認できるはずです。

Metrics Serverを削除するには以下コマンドです。
`Horizontal Pod Autoscaler(HPA)`を使用する場合は削除しないでください。

``` sh
cd $DIR/manifests/metrics-server
kubectl delete -f ./
```