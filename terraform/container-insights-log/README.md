# container-insihts-log

## 依存モジュール

- tf-backend

## 説明

`container-insihts-log`は[Container Insights](https://docs.aws.amazon.com/ja_jp/AmazonCloudWatch/latest/monitoring/ContainerInsights.html)に必要なリソースをデプロイするモジュールです。Container Insightsをクラスタへデプロイする前に実行してください。

Container InsightsはFluentdまたはFluent Bitを使用してログを収集します。本モジュールは`Fluent Bit`を想定しています。（Fluentdでも問題ないかもしれませんが試していません。）

### ロググループの作成

Container Insightsがログを送るCloudWatchのロググループを作成します。ContainerInsightsからロググループを作成することもできますが、保持期間の設定が無期限で作成されるため有効期限付きのロググループを作成します。Container Insightsがログを送る以下ロググループを作成します。

- /aws/containerinsights/<EKSクラスタ名>/application
- /aws/containerinsights/<EKSクラスタ名>/dataplane
- /aws/containerinsights/<EKSクラスタ名>/host

### ログのアーカイブ

CloudWatchに格納したログは自動的にKinesis Firehoseを経由してS3へアーカイブするように構成します。S3バケットやKibesis Firehouseも本モジュールで作成します。アーカイブされたログはさらに指定した日数後Glacierへ移行されます。Kinesis Firehoseの転送エラーなどのログは以下ロググループに出力します。このログは保持期間を1日設定しています。

- /aws/kinesisfirehose/<EKSクラスタ名>/logarchive/application
- /aws/kinesisfirehose/<EKSクラスタ名>/logarchive/dataplane
- /aws/kinesisfirehose/<EKSクラスタ名>/logarchive/host

## Container Insightsのデプロイ

本モジュールを実行した後、以下手順でContainer Insights（Fluent Bit）をデプロイします。

まず、ns:amazon-cloudwatchを作成します。

``` sh
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cloudwatch-namespace.yaml
```

Fluent BitのConfigmapを作成します。`ClusterName`や`RegionName`は自身の環境にあわせて修正してください。

``` sh
ClusterName=$PJ-$ENV
RegionName=$REGION
FluentBitHttpPort='2020'
FluentBitReadFromHead='Off'
[[ ${FluentBitReadFromHead} = 'On' ]] && FluentBitReadFromTail='Off'|| FluentBitReadFromTail='On'
[[ -z ${FluentBitHttpPort} ]] && FluentBitHttpServer='Off' || FluentBitHttpServer='On'
kubectl create configmap fluent-bit-cluster-info \
--from-literal=cluster.name=${ClusterName} \
--from-literal=http.server=${FluentBitHttpServer} \
--from-literal=http.port=${FluentBitHttpPort} \
--from-literal=read.head=${FluentBitReadFromHead} \
--from-literal=read.tail=${FluentBitReadFromTail} \
--from-literal=logs.region=${RegionName} -n amazon-cloudwatch
```

Fluent BitのDaemonSetをデプロイします。

``` sh
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/fluent-bit/fluent-bit.yaml
```

Fluent BitをデプロイしただけではCloudWatchにログを書き込む権限がありません。Fluent BitのPodを起動しているServiceAccountにCloudWatchを操作するためのIAMロールを付与します。[eks-iam-for-sa_container-insights-log](../eks-iam-for-sa_container-insights-log)モジュールで作成したIAMロールを使用すると楽です。以下のようにsa:fluent-bitのマニフェストを修正してください。

``` sh
kubectl edit sa -n amazon-cloudwatch fluent-bit
# annotationsに以下を追加
# eks.amazonaws.com/role-arn: <eks-iam-for-sa_container-insights-logのアウトプットに表示されるIAMロールのARN>
```

ServiceAccountを修正したらPodを再作成します。

``` sh
kubectl get pod -n amazon-cloudwatch
kubectl delete pod -n amazon-cloudwatch <Pod名>
```

PodがRunnnigし、CloudWatchの各ロググループにログが出力されているはずです。また、S3へのアーカイブも問題なくできていることを確認してください。