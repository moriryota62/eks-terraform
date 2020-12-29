
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
