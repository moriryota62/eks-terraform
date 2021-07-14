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
  - ターゲットグループはどちらも`test`（同じターゲットグループだとLBを共有する）
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

> もしADDRESSが表示されず、Ingressのイベントを確認して以下のメッセージがでる場合、sa-for-iamで付与した`pj-env-SAIAM-kube-system-aws-load-balancer-controller`のIAMポリシーに不備がある可能性があります。
>> couldn't auto-discover subnets: UnauthorizedOperation: You are not authorized to perform this operation
> 今のIAMポリシーはコントローラのバージョンがv2.2.1で動作確認しています。このIAMポリシーは以下コマンドでDLしたものです。もし、コントローラのバージョンが違う場合、以下コマンドのバージョン部分を修正し、IAMを再作成してください。
>> curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.2.1/docs/install/iam_policy.json

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
