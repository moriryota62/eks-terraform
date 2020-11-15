- [モジュール](#モジュール)
  - [ネットワーク](#ネットワーク)

# モジュール

本レポジトリのTerraformコードで実装しているモジュールについて説明します。



## ネットワーク

`ネットワーク`はVPCとパブリックサブネットおよびプライベートサブネットを構築するterraformモジュールです。インターネットゲートウェイやNATゲートウェイ、ECRとS3へのエンドポイントも構築します。このモジュールで作成した`VPCのID`や`サブネットのID`は他のモジュールでも使用します。このモジュールはVPCがない場合などに実行ください。すでにVPCやサブネットがある場合はそれらのIDを他モジュールで使用してください。

[クラスター VPC に関する考慮事項(https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/network_reqs.html)]に記載さているタグをVPCおよびサブネットに付与します。

```
# EKSからサブネットを認識するためのタグ
"kubernetes.io/cluster/${var.cluster_name}" = "shared"

# type:LB使用のため
## for public subnet
"kubernetes.io/role/elb" = 1
## for private subent
"kubernetes.io/role/internal-elb" = 1
```