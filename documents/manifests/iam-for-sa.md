# IAM for ServiceAccount

EKSではPodに直接IAMロールを割り当てる事ができます。
これをしない場合、EKSのワーカーノードにIAMロールをアタッチすることになります。
そうすると、権限はワーカーノード上で動くすべてのPodに付与されてしまいます。
IAM for SAを設定することで、Podごとにきめ細やかな権限を設定できます。

IAM for SAはクラスターにIAMOIDCプロバイダーを作成し、AWS側のIAMポリシーおよびIAMロールとK8s内のServiceAccountを使って設定します。

本レポジトリのterraformはデフォルトでIAMOIDCプロバイダーを作成するように作られています。
そのため、IAMOIDCプロバイダーの作成はとくに行う必要ありません。

Podに付与させたいIAMポリシーを設定したIAMロールを作成します。
この際、クラスターのIAMOIDCプロバイダーを信頼できるエンティティに追加します。
また、条件としてK8s内のNamespaceとServiceAccountも設定します。
この設定を簡略化するため、本レポジトリのterrafromでは`eks-iam-for-sa`モジュールを用意しています。
本レポジトリのデフォルトでは`$PJ-$ENV-SAIAM-default-iam-test`という名前のIAMロールをサンプルとして用意しています。

K8s内のServiceAccountには関連付けるIAMロールのARNをannotationsで指定します。
あとはPod（またはDeployment）のマニフェストにて上記関連付けたServiceAccountでPodを起動するように設定します。

以下、実際にIAM for SAでPodにIAMロールを付与する例を確認します。

サンプルマニフェストが配置してあるディレクトリに移動します。

``` sh
cd $DIR/manifests/iam-for-sa
```

配置してあるマニフェストをapplyします。
なお、マニフェストは本レポジトリのterraformがサンプルとして用意している`PJ-$ENV-SAIAM-default-iam-test`というIAMロールがある前提で設定しています。
もし、上記のIAMロールがない場合はあらかじめIAM for SAで使用できるIAMロールを準備し、マニフェストを書き換えてください。

``` sh
kubectl apply -f ./
```

applyしたマニフェストは以下のようなリソースです。

- ServiceAccountを設定していない（defaultのServiceAccountを使用する）Deployment
- ServiceAccount:iam-testでPodを起動するDeployment
- IAMロール`PJ-$ENV-SAIAM-default-iam-test`を関連付けたServiceAccount:ima-test
  - IAMロール`PJ-$ENV-SAIAM-default-iam-test`はCloudWatchに対するすべての操作を許可したロールです。

Podが起動できていることを確認します。

``` sh
kubectl get pod
```

以下のようにPodが起動できていれば良いです。

```
NAME                           READY   STATUS    RESTARTS   AGE
sa-default-8679f95fbc-tf9df    1/1     Running   0          32s
sa-iam-test-558fb56cf6-75rz7   1/1     Running   0          31s
```

まずはServiceAccountを設定していない`sa-default-XXXXX`のPodにログインします。
以下コマンド例です。Pod名は自身の環境に合わせて変えてください。

``` sh
kubectl exec -it sa-default-8679f95fbc-tf9df /bin/sh
```

このPodはawsコマンドを使用できます。
CloudWatchに対してコマンドを実行します。
IAMロールを付与していないため、コマンドが失敗します。

``` sh
aws logs describe-log-groups
```

権限がない場合は以下のようなメッセージが出ます。

```
An error occurred (AccessDeniedException) when calling the DescribeLogGroups operation: User: arn:aws:sts::456247443832:assumed-role/pj-env-eks-node-group/i-01eb13755a5e9457e is not authorized to perform: logs:DescribeLogGroups on resource: arn:aws:logs:us-east-2:456247443832:log-group::log-stream:
```

Podからログアウトします。

``` sh
exit
```

続いて`sa-iam-test-XXXXX`のPodにログインします。
以下コマンド例です。Pod名は自身の環境に合わせて変えてください。

``` sh
kubectl exec -it sa-iam-test-558fb56cf6-75rz7 /bin/sh
```

さきほどと同じくCloudWatchに対してコマンドを発行します。
今度はログループが表示されます。

``` sh
aws logs describe-log-groups
```

以下のようにロググループが表示されます。

```
{
    "logGroups": [
        {
            "logGroupName": "/aws/containerinsights/EKS-U7wJKbnuGKyz/application",
            "creationTime": 1575000959459,
            "metricFilterCount": 0,
            "arn": "arn:aws:logs:us-east-2:456247443832:log-group:/aws/containerinsights/EKS-U7wJKbnuGKyz/application:*",
            "storedBytes": 5940254825
        },
...
```

IAMロールで与えたとおり、作成削除ができることも確認します。

``` sh
aws logs create-log-group --log-group-name test
aws logs describe-log-groups --log-group-name test
aws logs delete-log-group --log-group-name test
aws logs describe-log-groups --log-group-name test
```

確認できたらPodからログアウトします。

``` sh
exit
```

以上の通り、IAM for SAを使用することでPodごとにIAMロールを付与できます。
サンプルのリソースが不要な場合は以下コマンドで削除します。

``` sh
kubectl delete -f ./
```
