# container-insihts-log

## 依存モジュール

- tf-backend
- eks

## 説明

`container-insihts-log`は[Container Insights](https://docs.aws.amazon.com/ja_jp/AmazonCloudWatch/latest/monitoring/ContainerInsights.html)に必要なリソースをデプロイするモジュールです。Container Insightsをクラスタへデプロイする前に実行してください。

Container InsightsはFluentdまたはFluent Bitを使用してログを収集します。本モジュールは`Fluent Bit`を想定しています。（Fluentdでも問題ないかもしれませんが試していません。）

### ロググループの作成

Container Insightsがメトリクスを送るCloudWatchのロググループを作成します。ContainerInsightsからロググループを作成することもできますが、保持期間の設定が無期限で作成されるため有効期限付きのロググループを作成します。Container Insightsがログを送る以下ロググループを作成します。

- /aws/containerinsights/<EKSクラスタ名>/performance

### ログのアーカイブ

CloudWatchに格納したログは自動的にKinesis Firehoseを経由してS3へアーカイブするように構成します。S3バケットやKibesis Firehouseも本モジュールで作成します。アーカイブされたログはさらに指定した日数後Glacierへ移行されます。Kinesis Firehoseの転送エラーなどのログは以下ロググループに出力します。このログは保持期間を1日設定しています。

- /aws/kinesisfirehose/<EKSクラスタ名>/logarchive/performance

## Container Insights（CloudWatch Agent）のデプロイ

本モジュールを実行した後、以下手順でContainer Insights（CloudWatch Agent）をデプロイします。

まず、ns:amazon-cloudwatchを作成します。（[container-insights-log](../container-insights-log/)で作成済の場合は飛ばして構いません。）

``` sh
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cloudwatch-namespace.yaml
```

CloudWatch Agent用のServiceAccountを作成します。

``` sh
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cwagent/cwagent-serviceaccount.yaml
```

このままだとまだCloudWatch AgentからCloudWatchにログを書き込む権限がありません。CloudWatch AgentのPodを起動しているServiceAccountにCloudWatchを操作するためのIAMロールを付与します。[eks-iam-for-sa_container-insights-metrics](../eks-iam-for-sa_container-insights-metrics)モジュールで作成したIAMロールを使用すると楽です。以下のようにsa:fluent-bitのマニフェストを修正してください。

``` sh
kubectl edit sa -n amazon-cloudwatch cloudwatch-agent
# annotationsに以下を追加
# eks.amazonaws.com/role-arn: <eks-iam-for-sa_container-insights-metricsのアウトプットに表示されるIAMロールのARN>
```

CloudWatch AgentのConfigmapを作成します。以下コマンドでマニフェストを入手してください。

``` sh
curl -O https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cwagent/cwagent-configmap.yaml
```

ダウンロードしたマニフェストの`{{cluster_name}}`をクラスタ名に修正します。また、他にもメトリクスを収集する間隔等のオプションを指定できます。パラメータの説明については[こちら](https://docs.aws.amazon.com/ja_jp/AmazonCloudWatch/latest/monitoring/Container-Insights-setup-metrics.html#create-configmap)のAWSドキュメントを確認ください。

修正したらマニフェストをデプロイします。

``` sh
kubectl apply -f cwagent-configmap.yaml
```

CloudWatch AgentのDaemonSetをデプロイします。

``` sh
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cwagent/cwagent-daemonset.yaml
```
