- [EKS構成](#eks構成)
  - [EKS](#eks)
  - [EKS Managed Node Group](#eks-managed-node-group)
  - [Fargate](#fargate)
  - [Network](#network)
  - [EFS](#efs)
  - [KMS](#kms)
  - [Container Insights](#container-insights)
    - [ログ](#ログ)
    - [メトリクス](#メトリクス)

# EKS構成

本レポジトリのTerraformで作成するEKS構成について説明します。
全体像は以下の通りです。

![全体像](./over-view.svg)

## EKS

EKSクラスターを1つ作成します。
作成するEKSクラスターの設定は以下の通りです。

- API Serverへは任意のCIDRからアクセスを許可
- 以下のログをCloudWatchに保存
  - api
  - audit
  - authenticator
  - controllerManager
  - scheduler
- KMSによるEKS内に保存するSecretの暗号化を有効

## EKS Managed Node Group

Podを動かすEC2タイプのノードグループを作成できます。
ノードグループで作成するEC2のスペック（マシンタイプ、ディスク容量）を任意に設定できます。

## Fargate

Podを動かすFargateタイプのプロファイルを作成できます。
Fargateで動かすNamespaces、Podのタグを任意に設定できます。

## Network

以下のネットワークを作成します。

- 任意のリージョンにVPCを作成する
- 2つの異なるAZにパブリックサブネットとプライベートサブネットを2つずつ作成する
- インターネットゲートウェイを作成する
- 各パブリックサブネットにNATゲートウェイを作成し、プライベートサブネットからもインターネットアクセス可能にする
- ECRおよびS3へプライベートアクセスするためのエンドポイントを作成する

## EFS

Pod間の共有ボリュームとしてEFSを作成できます。
EFSは任意のアクセスポイントを作成することもできます。

## KMS

K8sのSecretおよびEFSを暗号化するための鍵を作成します。

## Container Insights

EKSの監視ソリューションであるContainer Insightsを利用するためのリソース群も作成します。ログおよびメトリクスのアーキテクチャは以下の通りです。

### ログ

![ログ](./containerinsights-Log.svg)

- Container Insightsがログを送るロググループをログの保管期限付きで作成する
- 格納されたログはさらにサブスクリプションフィルタでそれぞれ以下2通りのアクションが行われる
  - すべてのログ
    - Kinesis Data Firehoseを経由してS3（標準）へ格納される
    - S3（標準）に格納したログは指定期間をすぎるとS3 Glacierへ移行される
  - 指定文字列を含むログ
    - Lambdaを経由してSNSから指定したEメールアドレスにEメールを送信する

### メトリクス

![メトリクス](./containerinsights-Metrics.svg)

- Container Insightsがログを送るロググループをログの保管期限付きで作成する
- 格納されたログはさらにサブスクリプションフィルタで以下のアクションが行われる
  - すべてのログ
    - Kinesis Data Firehoseを経由してS3（標準）へ格納される
    - S3（標準）に格納したログは指定期間をすぎるとS3 Glacierへ移行される
- メトリクスはアラームでしきい値監視を行う。条件が満たされるとSNSから指定したEメールアドレスにEメールを送信する

