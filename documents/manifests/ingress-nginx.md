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

``` 
NAME                                 TYPE           CLUSTER-IP       EXTERNAL-IP                                                                     PORT(S)                      AGE
ingress-nginx-controller             LoadBalancer   172.20.1.67      a97ed4bfe1eea425fa26f445f2c76927-f72262769e8aa441.elb.us-east-2.amazonaws.com   80:30003/TCP,443:31777/TCP   7m44s
ingress-nginx-controller-admission   ClusterIP      172.20.226.229   <none>                                                                          443/TCP                      7m45s
```

サンプルマニフェストを配置してディレクトリに移動してください。

``` sh
cd $DIR/manifests/nginx-ingress/test
```

サンプルマニフェストをapplyします。
このサンプルマニフェストはnic-ingress-1および2という名前のPodを作成します。
このPodは`localhost/nic-ingress-1/test/`および``localhost/alb-ingress-2/test/``にアクセスすると各Pod固有のメッセージを返します。
Nginx Ingress ControllerのServiceに上記パスを指定してアクセスするとELBを経由し、Ingress Controllerへ届き、Ingress Controllerが宛先のパスを判断して然るべきServiceへトラフィックを流します。

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

NAME            CLASS    HOSTS   ADDRESS                                                                         PORTS   AGE
nic-ingress-1   <none>   *       a99fbfe9f78ab4425b4e5d4e44cf134e-8414ed5a67304802.elb.us-east-2.amazonaws.com   80      16m
nic-ingress-2   <none>   *       a99fbfe9f78ab4425b4e5d4e44cf134e-8414ed5a67304802.elb.us-east-2.amazonaws.com   80      16m
```

作業端末のWebブラウザ等で以下のアドレスにアクセスします。
ALB Controllerを経由し、パスに応じて適切なPodへ接続できることを確認します。

- http://a99fbfe9f78ab4425b4e5d4e44cf134e-8414ed5a67304802.elb.us-east-2.amazonaws.com/nic-ingress-1/
- http://a99fbfe9f78ab4425b4e5d4e44cf134e-8414ed5a67304802.elb.us-east-2.amazonaws.com/nic-ingress-2/

以上のようにIngressを使いホストベースのルーティングが行えました。


サンプル用のリソースを削除します。

``` sh
kubectl delete -f ./
```

Ingress Controllerも不要であれば以下コマンドで削除します。

``` sh
cd ../
kubectl delete -f deploy.yaml
```
