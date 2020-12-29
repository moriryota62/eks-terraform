# EFSのマウント

EKSでEFSを使用する方法はいくつかあります。
代表的な方法として`EFS CSI Driver`を使用する方法と`EFS Provisioner`を使用する方法を紹介します。
両方の方法を同時に採用することもできます。

`EFS CSI Driver`は新たに開発されたものでいずれはこちらの方法がスタンダードになると思われます。
しかし、2020/11時点ではまだ開発中であり、Dynamic Volume Provisoning（以下、DVP）に対応していません。
そのため、用途ごとに領域を確保したい場合、手動でアクセスポイントを作成し、PersistentVolumeをapplyする手間が必要です。
一方、Fargateで起動しているPodに対してもボリューム提供できる点は`EFS Provisioner`にはない利点です。

`EFS Provisioner`は上記`EFS CSI Driver`のような手間はいりません。
ですが、Fargateで起動しているPodにはボリューム提供ができません。
一方、DVPが可能な点は`EFS CSI Driver`にはない利点です。
