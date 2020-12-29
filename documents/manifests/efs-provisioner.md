## EFS Provisionerを使用する場合

[EFS Provisioner](https://github.com/kubernetes-retired/external-storage/tree/master/aws/efs)を導入します。

EFS Provisionerのマニフェストは上記公式のレポジトリにありますが、以下ディレクトリにも配置しています。
なお、公式のマニフェストはDeploymentのapiVersionが`extensions/v1beta1`になっているなどK8s v1.15まででしか使えない記述があります。
以下ディレクトリに配置しているマニフェストはK8s v1.18でも動作するように修正してあります。
また、EFS Provisioner関連のK8sリソースはNamespaces:`efs-provisioner`に作成するようにも修正しています。

``` sh
cd $DIR/manifests/efs-provisioner
```

`manifest.yaml`に含まれる`yourEFSsystemid`と`yourEFSregion`を修正します。
`yourEFSsystemid`はterraform実行後に表示される`efs_id`の値を使います。
以下は修正するコマンド例です。

**Linuxの場合**

``` sh
sed -i -e 's:yourEFSregion:'$REGION':g' manifest.yaml
sed -i -e 's:yourEFSsystemid:fs-d05b35a8:g' manifest.yaml
```

**macの場合**

``` sh
sed -i "" -e 's:yourEFSregion:'$REGION':g' manifest.yaml
sed -i "" -e 's:yourEFSsystemid:fs-d05b35a8:g' manifest.yaml
```

まずEFS ProvisionerをデプロイするNamespace:`efs-provisioner`を作ります。

``` sh
kubectl apply -f ns.yaml
```

続いて、EFS Provisionerをデプロイします。

``` sh
kubectl apply -f rbac.yaml -f manifest.yaml
```

EFS Provisionerが作成できたことを確認します。以下の様にPodがRunningになっていれば良いです。

``` sh
kubectl get pod -n efs-provisioner
```

表示例

```
NAME                              READY   STATUS    RESTARTS   AGE
efs-provisioner-bc5dc9c84-pvdcm   1/1     Running   0          67s
```

また、StorageClassを確認し、`aws-efs`があることを確認します。

``` sh
kubectl get storageclass
```

表示例

```
NAME            PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
aws-efs         example.com/aws-efs     Delete          Immediate              false                  3m49s
gp2 (default)   kubernetes.io/aws-ebs   Delete          WaitForFirstConsumer   false                  56m
```

以上でEFS Provisionerの準備は完了です。
テスト用のマニフェストを使用し、EFSのマウントができるか確認します。
テスト用のマニフェストを配置しているディレクトリに移動します。

``` sh
cd $DIR/manifests/efs-provisioner/test
```

`efs-mount-1`と`efs-mount-2`の2つのDeploymentとPersistentVolumeClaimを用意しています。
Deploymentでは/test1または/test2にEFSをマウントする様に記述しています。
以下コマンドでapplyします。

``` sh
kubectl apply -f ./
```

デプロイできたか確認します。どちらもRunningになれば良いです。

``` sh
kubectl get pod
```

表示例

```
NAME                           READY   STATUS    RESTARTS   AGE
efs-mount-1-5dfcc844dc-xtml9   1/1     Running   0          32s
efs-mount-2-7c5ff5487b-5pkz5   1/1     Running   0          31s
```

それぞれEFSでマウントしている領域に書き込みします。
以下はコマンド例です。Pod名は自身の環境にあわせて修正してください。

``` sh
kubectl exec efs-mount-1-5dfcc844dc-xtml9 touch /test1/efs-test-1
kubectl exec efs-mount-2-7c5ff5487b-5pkz5 touch /test2/efs-test-2
```

Podを削除します。
以下はコマンド例です。Pod名は自身の環境にあわせて修正してください。

``` sh
kubectl delete pod efs-mount-1-5dfcc844dc-xtml9
kubectl delete pod efs-mount-2-7c5ff5487b-5pkz5
```

しばらくしてからPodがセルフヒーリングされていることを確認します。

``` sh
kubectl get pod
```

表示例

```
NAME                           READY   STATUS    RESTARTS   AGE
efs-mount-1-5dfcc844dc-pn2bf   1/1     Running   0          39s
efs-mount-2-7c5ff5487b-dnbqc   1/1     Running   0          24s
```

セルフヒーリング後のPodを確認し、ボリュームが永続化できていることを確認します。
以下はコマンド例です。Pod名は自身の環境にあわせて修正してください。

``` sh
kubectl exec efs-mount-1-5dfcc844dc-pn2bf ls /test1/
kubectl exec efs-mount-2-7c5ff5487b-dnbqc ls /test2/
```

また、以下のようにPodをスケールさせます。

``` sh
kubectl scale deployment efs-mount-1 --replicas=3
```

Podがスケールされていることを確認します。

``` sh
kubectl get pod
```

表示例

```
NAME                           READY   STATUS    RESTARTS   AGE
efs-mount-1-5dfcc844dc-jbwhf   1/1     Running   0          39s
efs-mount-1-5dfcc844dc-pn2bf   1/1     Running   0          4m19s
efs-mount-1-5dfcc844dc-wfr6g   1/1     Running   0          39s
efs-mount-2-7c5ff5487b-dnbqc   1/1     Running   0          4m4s
```

`efs-mount-1`のさきほど確認したのとは違うPodを指定してボリュームが共有できていることを確認します。
以下はコマンド例です。Pod名は自身の環境にあわせて修正してください。

``` sh
kubectl exec efs-mount-1-5dfcc844dc-jbwhf ls /test1/
```

以上で確認は終わりです。
テスト用のリソースをすべて削除します。
なお、これで削除するのはK8sリソースのみです。
EFSに保存したefs-test-1やefs-test-2はEFS内に残っているので注意ください。

``` sh
kubectl delete -f ./
cd ../
# EFS Provisionerを引き続き使用する場合は以下コマンドは実施しなくてよいです。
kubectl delete -f ./
```
