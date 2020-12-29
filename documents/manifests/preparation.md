# 事前準備

[使い方](./../howtouse.md)から続けて作業している場合は環境変数を設定済のため事前準備は不要です。
環境変数を設定していない場合は以下の手順で環境変数を設定してください。

作業用ディレクトリを環境変数に設定します。

``` sh
cd <eks-terraformのルートディレクトリ>
export DIR=`pwd`
```

以降の手順で複数のファイルで使用する基本設定値を環境変数に設定しておきます。

``` sh
export REGION=us-east-2
export PJ=pj
export ENV=env
export OWNER=owner
```

kubeconfigを設定していない場合は環境変数に設定します。

``` sh
export KUBECONFIG=<kubeconfigのパス>
```

以下コマンドでEKSとの接続を確認します。ノードが表示されれば接続できています。

``` sh
kubectl get node
```
