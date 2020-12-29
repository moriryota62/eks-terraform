## EFS CSI Driverを使用する場合

[EFS CSI Driver](https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/efs-csi.html)

EFS CSI Driverを使用してEFSをマウントします。
FaragateのPodでEFSを使用するならEFS CSI Driverを使用します。

EFS CSI Driver関連のマニフェストを配置したディレクトリに移動します。

``` sh
cd $DIR/manifests/efs-csi-driver
```

EFS CSI Driverは以下コマンドでデプロイします。2020/11現在は手動でデプロイする必要がありますが、将来的にはEKSに標準で組み込まれる予定です。

``` sh
kubectl apply -k "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/ecr/?ref=release-1.0"
```

EFS CSI Driverを指定した`StorageClass`をデプロイします。
`efs-csi-sc.yaml`をそのままapplyすれば良いです。

``` sh
kubectl apply -f efs-csi-sc.yaml
```

デプロイすると`PROVISIONERがefs.csi.aws.com`のStorageClassが追加されるので確認します。

``` sh
kubectl get storageclass
```

表示例

```
NAME            PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
efs-sc          efs.csi.aws.com         Delete          Immediate              false                  7s
gp2 (default)   kubernetes.io/aws-ebs   Delete          WaitForFirstConsumer   false                  10m
```

以上でEFS CSI Driverの準備は完了です。
テスト用のマニフェストを使用し、EFSのマウントができるか確認します。
テスト用のマニフェストを配置しているディレクトリに移動します。

``` sh
cd $DIR/manifests/efs-csi-driver/test
```

次に実際にEFS CSI Driverを使用してEFSをマウントする`Deployment`、`PersistentVolumeClaim`、`PersistentVolume`をデプロイします。
EFS CSI DriverはまだDVPに対応していないため、あらかじめPersistentVolumeを手動で作成します。

PersistentVolumeのマニフェストはEFSのファイルシステムIDを指定するため、自身の環境にあわせて修正する必要があります。
また、EFS CSI DriverでEFSをマウントするとEFSの/をマウントしてしまいます。
複数用途でひとつのEFSを利用する場合、EFSアクセスポイントで用途ごとのアクセスポイントを作成するのがよいです。
サンプルで用意したTerraformでは/test1と/test2のアクセスポイントを作成します。
PersistenVolumeのマニフェストのvolumeHandleに`<EFS ID>::<アクセスポイントID>`という形式で指定します。（Terraform実行後のoutputに表示される`access_points`はこの形式で出力しています）

`efs-csi-pv-1.yaml`および`efs-csi-pv-2.yaml`を自身の環境にあわせて修正してください。

``` sh
vi efs-csi-pv-1.yaml
vi efs-csi-pv-2.yaml
```

修正例

``` yaml
~略~
  csi:
    driver: efs.csi.aws.com
    volumeHandle: fs-a0076cd8::fsap-0fa1ab4ffc5f4a92f # この部分
```

修正したら以下コマンドでデプロイします。FargateなのでPod起動には少し時間がかかります。
2分ほど時間をおいてからget podしてください。
もし、pendingのままの場合はkubectl describe pod <pod名>を確認してください。
「Pod provisioning timed out」している場合はkubectl delete pod <pod名>でpodを再作成すると良いかもしれません。

``` sh
kubectl apply -f efs-csi-pv-1.yaml -f efs-csi-pv-2.yaml
kubectl apply -f efs-csi-pvc-1.yaml -f efs-csi-pvc-2.yaml
kubectl apply -f efs-csi-mount-deployment-1.yaml -f efs-csi-mount-deployment-2.yaml
kubectl get pod
```

表示例

```
NAME                               READY   STATUS    RESTARTS   AGE
efs-mount-csi-1-6c4c8b5669-4cdfc   1/1     Running   0          6m
efs-mount-csi-2-5876f5bbbd-m8kls   1/1     Running   0          2m19s
```

それぞれEFSでマウントしている領域に書き込みします。
以下はコマンド例です。Pod名は自身の環境にあわせて修正してください。

``` sh
kubectl exec efs-mount-csi-1-6c4c8b5669-4cdfc touch /test1/efs-test-1
kubectl exec efs-mount-csi-2-5876f5bbbd-m8kls touch /test2/efs-test-2
```

Podを削除します。
以下はコマンド例です。Pod名は自身の環境にあわせて修正してください。

``` sh
kubectl delete pod efs-mount-csi-1-6c4c8b5669-4cdfc
kubectl delete pod efs-mount-csi-2-5876f5bbbd-m8kls
```

しばらくしてからPodがセルフヒーリングされていることを確認します。

``` sh
kubectl get pod
```

表示例

```
NAME                               READY   STATUS    RESTARTS   AGE
efs-mount-csi-1-6c4c8b5669-smfqh   1/1     Running   0          99s
efs-mount-csi-2-5876f5bbbd-ww7vj   1/1     Running   0          95s
```

セルフヒーリング後のPodを確認し、ボリュームが永続化できていることを確認します。
以下はコマンド例です。Pod名は自身の環境にあわせて修正してください。

``` sh
kubectl exec efs-mount-csi-1-6c4c8b5669-smfqh ls /test1/
kubectl exec efs-mount-csi-2-5876f5bbbd-ww7vj ls /test2/
```

また、以下のようにPodをスケールさせます。

``` sh
kubectl scale deployment efs-mount-csi-1 --replicas=3
```

Podがスケールされていることを確認します。

``` sh
kubectl get pod
```

表示例

```
NAME                               READY   STATUS    RESTARTS   AGE
efs-mount-csi-1-6c4c8b5669-d4ddj   1/1     Running   0          5m22s
efs-mount-csi-1-6c4c8b5669-jqvpw   1/1     Running   0          5m22s
efs-mount-csi-1-6c4c8b5669-smfqh   1/1     Running   0          8m17s
efs-mount-csi-2-5876f5bbbd-ww7vj   1/1     Running   0          8m13s
```

`efs-mount-1`のさきほど確認したのとは違うPodを指定してボリュームが共有できていることを確認します。
以下はコマンド例です。Pod名は自身の環境にあわせて修正してください。

``` sh
kubectl exec efs-mount-csi-1-6c4c8b5669-d4ddj ls /test1/
```

以上で確認は終わりです。
テスト用のリソースをすべて削除します。
なお、これで削除するのはK8sリソースのみです。
EFSに保存したefs-test-1やefs-test-2はEFS内に残っているので注意ください。

``` sh
kubectl delete -f ./
cd ../
# EFS CSI Driverを引き続き使用する場合は以下コマンドは実施しなくてよいです。
kubectl delete -f efs-csi-sc.yaml
kubectl delete -k "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/ecr/?ref=release-1.0"
```
