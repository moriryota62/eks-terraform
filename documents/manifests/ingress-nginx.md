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
