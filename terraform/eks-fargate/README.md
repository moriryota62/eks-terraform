# eks-fargate

## 依存モジュール

- tf-backend
- network
- eks

## 説明

`eks-fargate`はEKSのFargateプロファイルを作成するモジュールです。Fargateはプライベートサブネットに関連づけられています。

あるNamespaceのすべてのPodをFargateで動かしたい場合`namespace`のみ設定し、`labels`は空（{}）を指定してください。ちなみに、`namespace`の設定は必須です。

### フルFargate構成の場合

EC2タイプのワーカーを構成せず、Fargateだけで構成するには以下のように`terraform.tfvars`に設定してください。

```
eks-fargate_profiles = {
  "kube-system" = { namespace = "kube-system", labels = {} },
  "default"     = { namespace = "default", labels = {} }
}
```

また、Fargateプロファイルを作成した後、ns:kube-systemのPod状態を確認してください。おそらくCoreDNSがPendingになっているはずです。これはCoreDNSがEC2タイプのワーカーにデプロイされるように設定されているためです。CoreDNSのDeploymentを`kubectl edit deployment`で修正します。annotaionsに`eks.amazonaws.com/compute-type : ec2`があるはずなので削除してください。マニフェスト更新後、しばらくするとCoreDNSがFargateで起動します。

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
| base\_name | 作成するリソースに付与する接頭語 | `string` | n/a | yes |
| eks-fargate\_profiles | Fargateプロファイルの設定。Fargateプロファイルを作成しない場合は空マップ「{}」にする。 | <pre>map(object({<br>    namespace    = string<br>    labels       = map(string)<br>  }))</pre> | n/a | yes |

## Outputs

No output.