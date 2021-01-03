# Prometheus

PrometheusはK8sのメトリクス監視によく使用されるツールです。

Prometheus用のNamespaceを作成します。

``` sh
kubectl create namespace prometheus
```

helmでPrometheusをデプロイします。

``` sh
helm install prometheus stable/prometheus \
    --namespace prometheus \
    --set alertmanager.persistentVolume.storageClass="gp2",server.persistentVolume.storageClass="gp2"
```

もし以下のようなエラーが出る場合は`helm repo add stable https://charts.helm.sh/stable`を実行してから上記コマンドでデプロイしてください。

```
Error: failed to download "stable/prometheus" (hint: running `helm repo update` may help)
```

デプロイ確認

``` sh
kubectl get pod -n prometheus
```

以下のようにPrometheus関連のPodが表示されれば良いです。

```
NAME                                            READY   STATUS    RESTARTS   AGE
prometheus-alertmanager-6b64586d49-tzjc2        2/2     Running   0          6m30s
prometheus-kube-state-metrics-c65b87574-7j68v   1/1     Running   0          6m30s
prometheus-node-exporter-4k8bc                  1/1     Running   0          6m30s
prometheus-pushgateway-7d5f5746c7-twv2m         1/1     Running   0          6m30s
prometheus-server-f8d46859b-wrvg8               2/2     Running   0          6m30s
```

prometheusにwebブラウザで接続するため、ポートフォワードを設定します。
以下コマンドを実行します。

``` sh
kubectl --namespace=prometheus port-forward deploy/prometheus-server 9090
```

webブラウザを開き、`localhost:9090`にアクセスします。

**expression**に`container_memory_usage_bytes`と入力して**execute**をクリックします。
Graphタブに各Podの使用量のグラフが表示されるはずです。

確認が終わったらポートフォファードを`Ctl-c`などで終了します。

以上でPrometheusのデプロイは完了です。

削除する場合は以下コマンドです。

``` sh
helm uninstall prometheus -n prometheus
kubectl delete ns prometheus
```