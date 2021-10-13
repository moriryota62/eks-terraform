# container-insihts-log

## 依存モジュール

- tf-backend
- eks

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

### ログの通知

ロググループごとにサブスクリプションフィルタを設定して任意の文字列が出力された時にSNSで通知できます。サブスクリプションフィルタ、Lambda、SNSも本モジュールで作成します。通知の必要がないロググループは`variables.tf`の`filter_pattern`に`null`を設定してください。

## Container Insights（Fluent Bit）のデプロイ

本モジュールを実行した後、以下手順でContainer Insights（Fluent Bit）をデプロイします。

まず、ns:amazon-cloudwatchを作成します。（[container-insights-metrics](../container-insights-metrics/)で作成済の場合は飛ばして構いません。）

``` sh
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cloudwatch-namespace.yaml
```

Fluent BitのConfigmapを作成します。`ClusterName`や`RegionName`は自身の環境にあわせて修正してください。

``` sh
ClusterName=project-environment
RegionName=ap-northeast-1
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

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13.5 |

## Providers

| Name | Version |
|------|---------|
| aws | n/a |
| terraform | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| base\_name | リソース群に付与する接頭語 | `string` | n/a | yes |
| endpoint | 通知する先のメールアドレス | `list(string)` | n/a | yes |
| log\_groups | ロググループの一覧。<br>retention\_in\_daysはCloudWatchの保持日数。<br>transition\_glacier\_daysはGlacierへ移行する日数。<br>filter\_patternはログ通知のトリガにする文字列。<br>通知が不要な場合filter\_patternにnullを設定する。 | <pre>map(object({<br>    retention_in_days = number<br>    transition_glacier_days = number<br>    filter_pattern = string<br>  }))</pre> | n/a | yes |

## Outputs

No output.