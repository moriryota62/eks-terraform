# Ingress

IngressはK8s内のL7ロードバランサのようなものです。
K8s内に作成したサービス（アプリケーション）をK8s外へ公開する際によく使います。
ホストベースのルーティングをIngressを使用して実装します。

IngressはIngressの動作をコントロールする`Ingress Controller`とK8s内のリソースである`Ingress`の2つで成り立ちます。
`Ingress Controller`にはいくつか種類があります。[こちら](https://kubernetes.io/ja/docs/concepts/services-networking/ingress-controllers/)を参照ください。
EKSの場合、`NGINX Ingress Controller`か`AWS Load Balancer Controller`のいずれかが良いでしょう。
本手順ではこの2つの導入方法について解説します。

[NGINX Ingress Controller](https://kubernetes.io/ja/docs/concepts/services-networking/ingress-controllers/)は古くからあるIngress ControllerでAWS以外のクラウドでも同じように使うことのできるコントローラです。
K8s内にControllerのPodとService type:LBでAWSにELBをデプロイし連携させることで動作します。
`AWS Load Balancer Controller`よりも歴史が古いため、世の中のナレッジも豊富です。

[AWS Load Balancer Controller](https://github.com/kubernetes-sigs/aws-load-balancer-controller)はAWSのALBを使用したIngress Controllerです。
以前は`ALB Ingress Controller`と呼ばれていましたが2020年10月に後継となる`AWS Load Balancer Controller`がリリースされました。
K8s内にControllerのPodをデプロイします。
FargateのPodにもルーティングできます。
ELBはK8sのServiceとして管理するのではなく、`AWS Load Balancer Controller`が管理します。
利用者はIngressリソースをデプロイする際にIngressGroupを指定します。
