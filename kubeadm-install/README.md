# kubeadm 安装kubernetes

## 准备环境

### 服务器

服务器情况：

| IP | 系统版本 | 角色 | Hostname |
| --- | --- | --- | --- |
| 10.20.13.24 | Centos7 64位 | master | kuber24 |
| 10.20.13.25 | Centos7 64位 | work | Kuber25 |
| 10.20.13.26 | Centos7 64位 | work | Kuber26 |
| 10.20.13.27 | Centos7 64位 | work | Kuber27 |

### 修改host
 ansible 脚本,hostname = kuber[ip最后8位]：

```yml
---
- hosts: k8
  remote_user: root
  tasks:
  - name: origin hostname
    command: hostname
  - name: server ip
    shell: ip a
  - hostname: name=kuber{{ ansible_default_ipv4.address.split('.')[-1] }}
```

### 关闭firewall
linux 命令：

```shell

```

ansible playbook

```yml
---
- hosts: k8
  remote_user: root
  tasks:
  - name:  stop firewalld 
    systemd: name=firewalld enabled=false state=stopped
  - name: check firewalld status
    shell: service firewalld status
```

### 关闭swap分区

linux 命令：

```shell
swappoff -a
sed -i 's/.*swap.*/#&/' /etc/fstab
```

ansible playbook


```yml
---
- hosts: k8
  remote_user: root
  tasks:
  - name:  close swap 
    shell: swapoff -a && sed -i 's/.*swap.*/#&/' /etc/fstab
```


### ip转发参数

linux命令：

```shell
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system
```

ansible playbook

```yml
---
- hosts: k8
  remote_user: root
  tasks:
  - name:  copy k8s ip configs 
    copy: src='/etc/sysctl.d/k8s.conf' dest='/etc/sysctl.d/k8s.conf'
  - name: effect configs
    shell: sysctl --system
```


### 设置yum源

设置国内的阿里云 centos源。

linux 命令：

```shell
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
```

ansible playbook


```yml
---
- hosts: k8
  remote_user: root
  tasks:
  - name:  copy k8s ali repos 
    copy: src='/etc/yum.repos.d/kubernetes.repo' dest='/etc/yum.repos.d/kubernetes.repo'
```




### 安装必备工具

linux 命令：

```shell
yum install -y epel-release 
yum install -y net-tools wget vim  ntpdate
```

ansible playbook


```yml
---
- hosts: k8
  remote_user: root
  tasks:
  - name:  install epel repos 
    yum: pkg=epel-release state=latest
  - name:  install net tools 
    yum: pkg=net-tools state=latest
  - name:  install wget 
    yum: pkg=wget state=latest
  - name:  install vim 
    yum: pkg=vim state=latest
  - name:  install ntpdate 
    yum: pkg=ntpdate state=latest
```

### 安装docker

linux 命令：

```shell
yum install -y docker
systemctl enable docker && systemctl start docker
#设置系统服务，如果不设置后面 kubeadm init 的时候会有 warning
systemctl enable docker.service
```

ansible-playbook


```yml
---
- hosts: k8
  remote_user: root
  tasks:
  - name:  install docker 
    yum: pkg=docker state=latest
  - name: start docker and start when login
    systemd: name=docker enabled=true state=started
  - name: set up docker system service
    shell: systemctl enable docker.service
```


### 安装kubeadm kubelet kubectl kubernetes-cni

linux 命令：

```yml
yum install -y kubelet kubeadm kubectl kubernetes-cni
systemctl enable kubelet && systemctl start kubelet
```

ansible-playbook：


```yml
---
- hosts: k8
  remote_user: root
  tasks:
  - name:  install kubelet 
    yum: pkg=kubelet state=latest
  - name:  install kubeadm 
    yum: pkg=kubeadm state=latest
  - name:  install kubectl 
    yum: pkg=kubectl state=latest
  - name:  install kubernetes-cni 
    yum: pkg=kubernetes-cni state=latest
  - name: start kubelet service
    systemd: name=kubelet enabled=true state=started
 ```

### 完整的环境ansible-playbook


```yml
---
- hosts: k8
  remote_user: root
  vars:
  # cluster hostname prefix
  - HOST_PREFIX: kuber

  # bridge ip config file path
  - BRIDGE_CONF: ./k8s.conf

  # ali yun repos config file path
  - ALI_REPO_CONF: ./kubernetes.repo

  tasks:
  - name: origin hostname
    command: hostname
  - name: server ip
    shell: ip a
  - hostname: name={{HOST_PREFIX}}{{ ansible_default_ipv4.address.split('.')[-1] }}
  - name:  stop firewalld
    systemd: name=firewalld enabled=false state=stopped
  - name:  close swap
    shell: swapoff -a && sed -i 's/.*swap.*/#&/' /etc/fstab
  - name:  copy k8s ip configs
    copy: src='{{ BRIDGE_CONF }}' dest='/etc/sysctl.d/k8s.conf'
  - name: effect configs
    shell: sysctl --system
  - name:  copy k8s ali repos
    copy: src='{{ ALI_REPO_CONF }}' dest='/etc/yum.repos.d/kubernetes.repo'
  - name:  install epel repos
    yum: pkg=epel-release state=latest
  - name:  install net tools
    yum: pkg=net-tools state=latest
  - name:  install wget
    yum: pkg=wget state=latest
  - name:  install vim
    yum: pkg=vim state=latest
  - name:  install ntpdate
    yum: pkg=ntpdate state=latest
```


如果曾经安装过kubernetes，需要卸载相应的包，使用`rpm -qa|grep kube*`查找相关的包。然后使用`rpm -e 包名`。

例如我的环境：

`rpm -e kubernetes-1.5.2-0.7.git269f928.el7.x86_64  kubernetes-node-1.5.2-0.7.git269f928.el7.x86_64 kubernetes-master-1.5.2-0.7.git269f928.el7.x86_64  kubernetes-client-1.5.2-0.7.git269f928.el7.x86_64`


## 安装Master 节点


### 准备 kubernetes 镜像

因为国内没办法访问Google的镜像源，变通的方法是从其他镜像源下载后，修改tag。执行下面这个Shell脚本即可。


```shell
#!/bin/bash
images=(kube-proxy-amd64:v1.12.1 kube-scheduler-amd64:v1.12.1 kube-controller-manager-amd64:v1.12.1 kube-apiserver-amd64:v1.12.1
etcd-amd64:3.2.24 coredns:1.2.2 pause-amd64:3.1 kubernetes-dashboard-amd64:v1.10.0 k8s-dns-sidecar-amd64:1.14.13 k8s-dns-kube-dns-amd64:1.14.13 
k8s-dns-dnsmasq-nanny-amd64:1.14.13 )
for imageName in ${images[@]} ; do
  docker pull mirrorgooglecontainers/$imageName
  if [[ $imageName =~ "amd64" ]]; then
    docker tag mirrorgooglecontainers/$imageName "k8s.gcr.io/${imageName//-amd64/}"
  else
    docker tag mirrorgooglecontainers/$imageName k8s.gcr.io/$imageName
  fi
  # docker rmi mirrorgooglecontainers/$imageName
done
```

> 脚本的主要工作是获取镜像，然后将镜像的tag改为`k8s.gcr.io/$imageName`。

由于`mirrorgooglecontainers`没有`coredns:1.2.2`版本，所以需要从`hub.docker.com`查找coredns的官方发布版本，[https://hub.docker.com/r/coredns/coredns/](https://hub.docker.com/r/coredns/coredns/)。

拉取和改造coredns:1.2.2：


```shell
docker pull coredns/coredns:1.2.2
docker tag coredns/coredns:1.2.2 k8s.gcr.io/coredns:1.2.2
```

> 我怎么知道kurnernetes需要依赖哪些镜像？
> 直接运行kubeadm init 可以查看，因为需要科学上网，所以会超时，并且提示无法下载的镜像和版本。
> 目前已知kubernetes1.2.1的版本依赖的镜像：
> 
> ```
> k8s.gcr.io/kube-apiserver:v1.12.1
> k8s.gcr.io/kube-controller-manager:v1.12.1
> k8s.gcr.io/kube-scheduler:v1.12.1
> k8s.gcr.io/kube-proxy:v1.12.1
> k8s.gcr.io/etcd:3.2.24
> k8s.gcr.io/coredns:1.2.2
> k8s.gcr.io/etcd:3.2.24
> k8s.gcr.io/coredns:1.2.2
> ```




### Master 节点初始化

服务器使用了两块网卡，需要指定`apiserver-advertise-address`。

```shell
kubeadm init --kubernetes-version=v1.12.1 --pod-network-cidr=10.1.0.0/16 --apiserver-advertise-address=10.20.13.24
```

参数说明：

- `kubernetes-version`：安装的kubernetes版本
- `pod-network-cidr`: Pod网络的IP范围
- `apiserver-advertise-address`：建议的apiserver访问地址


执行日志：

```log
[root@kuber24 kubeadm-install]# kubeadm init --kubernetes-version=v1.12.1 --pod-network-cidr=10.1.0.0/16 --apiserver-advertise-address=10.20.13.24
[init] using Kubernetes version: v1.12.1
[preflight] running pre-flight checks
[preflight/images] Pulling images required for setting up a Kubernetes cluster
[preflight/images] This might take a minute or two, depending on the speed of your internet connection
[preflight/images] You can also perform this action in beforehand using 'kubeadm config images pull'
[kubelet] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[preflight] Activating the kubelet service
[certificates] Generated ca certificate and key.
[certificates] Generated apiserver certificate and key.
[certificates] apiserver serving cert is signed for DNS names [kuber24 kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 10.20.13.24]
[certificates] Generated apiserver-kubelet-client certificate and key.
[certificates] Generated front-proxy-ca certificate and key.
[certificates] Generated front-proxy-client certificate and key.
[certificates] Generated etcd/ca certificate and key.
[certificates] Generated apiserver-etcd-client certificate and key.
[certificates] Generated etcd/server certificate and key.
[certificates] etcd/server serving cert is signed for DNS names [kuber24 localhost] and IPs [127.0.0.1 ::1]
[certificates] Generated etcd/peer certificate and key.
[certificates] etcd/peer serving cert is signed for DNS names [kuber24 localhost] and IPs [10.20.13.24 127.0.0.1 ::1]
[certificates] Generated etcd/healthcheck-client certificate and key.
[certificates] valid certificates and keys now exist in "/etc/kubernetes/pki"
[certificates] Generated sa key and public key.
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/admin.conf"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/kubelet.conf"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/controller-manager.conf"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/scheduler.conf"
[controlplane] wrote Static Pod manifest for component kube-apiserver to "/etc/kubernetes/manifests/kube-apiserver.yaml"
[controlplane] wrote Static Pod manifest for component kube-controller-manager to "/etc/kubernetes/manifests/kube-controller-manager.yaml"
[controlplane] wrote Static Pod manifest for component kube-scheduler to "/etc/kubernetes/manifests/kube-scheduler.yaml"
[etcd] Wrote Static Pod manifest for a local etcd instance to "/etc/kubernetes/manifests/etcd.yaml"
[init] waiting for the kubelet to boot up the control plane as Static Pods from directory "/etc/kubernetes/manifests"
[init] this might take a minute or longer if the control plane images have to be pulled
[apiclient] All control plane components are healthy after 34.506899 seconds
[uploadconfig] storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config-1.12" in namespace kube-system with the configuration for the kubelets in the cluster
[markmaster] Marking the node kuber24 as master by adding the label "node-role.kubernetes.io/master=''"
[markmaster] Marking the node kuber24 as master by adding the taints [node-role.kubernetes.io/master:NoSchedule]
[patchnode] Uploading the CRI Socket information "/var/run/dockershim.sock" to the Node API object "kuber24" as an annotation
[bootstraptoken] using token: gnq0ex.j4wqxy6o89f7tl1a
[bootstraptoken] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstraptoken] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstraptoken] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstraptoken] creating the "cluster-info" ConfigMap in the "kube-public" namespace
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes master has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of machines by running the following on each node
as root:

  kubeadm join 10.20.13.24:6443 --token gnq0ex.j4wqxy6o89f7tl1a --discovery-token-ca-cert-hash sha256:c59abe1944573cd9568c45e8d29cec6c9201348d707633c04fbb3ccb7036f851

```

看到上述信息kubernetes Master 节点已经初始化成功。
初始化后的信息**十分关键**，**建议保存起来**

> 💡启发：
> 通过kubeadm的输出可以看出kubernetes的MASTER的核心安装步骤和配置文件的位置。
> 



```shell
#配置kubectl
export KUBECONFIG=/etc/kubernetes/admin.conf 
# 获取节点信息
kubectl get nodes

# 查看所有namespace的pods情况
kubectl get pods --all-namespaces
```

运行日志如下：


```shell
[root@kuber24 kubeadm-install]# export KUBECONFIG=/etc/kubernetes/admin.conf
[root@kuber24 kubeadm-install]# kubectl get nodes
NAME      STATUS     ROLES    AGE   VERSION
kuber24   NotReady   master   49m   v1.12.1
[root@kuber24 kubeadm-install]# kubectl get pods --all-namespaces
NAMESPACE     NAME                              READY   STATUS    RESTARTS   AGE
kube-system   coredns-576cbf47c7-75gcc          0/1     Pending   0          48m
kube-system   coredns-576cbf47c7-v242w          0/1     Pending   0          48m
kube-system   etcd-kuber24                      1/1     Running   0          48m
kube-system   kube-apiserver-kuber24            1/1     Running   0          48m
kube-system   kube-controller-manager-kuber24   1/1     Running   0          48m
kube-system   kube-proxy-nd875                  1/1     Running   0          48m
kube-system   kube-scheduler-kuber24            1/1     Running   0          48m
[root@kuber24 kubeadm-install]#
```

从上述结果可以看到，**kubermetes的coredns还是处于Pending状态，需要配置网络。**

### Master 节点网络设置


修改系统设置，创建 flannel 网络。


```
sysctl net.bridge.bridge-nf-call-iptables=1
```

启动flannel（如果服务器有多块网卡，或者需要更改网络信息，请先看完本小结内容）

```
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.10.0/Documentation/kube-flannel.yml
```

flannel 默认会使用主机的第一张网卡，如果你有多张网卡，需要通过配置单独指定。修改/添加`kube-flannel.yml` 中的`kube-flannel-ds(kind:DaemonSet):spec.template.spec.containers[0].args[3]`部分：

```yml
containers:
      - name: kube-flannel
        image: quay.io/coreos/flannel:v0.10.0-amd64
        command:
        - /opt/bin/flanneld
        args:
        - --ip-masq
        - --kube-subnet-mgr
        - --iface=enp0s3            #指定内网网卡,网卡名根据实际情况填
```

需要修改flannel 的网络配置，可以修改`ConfigMap`的`net-conf.json`字段：


```yml
  net-conf.json: |
    {
      "Network": "10.1.0.0/16",  # 此处根据实际情况修改flannel的网络范围,需要与kubeadm配置的--pod-network-cidr参数保持一致
      "Backend": {
        "Type": "vxlan"
      }
    }
```

如果flannel镜像下载出现问题，使用`docker pull rancher/coreos-flannel:v0.10.0`镜像，修改`kube-flannel.yml`的如下位置，来更新flannel pod使用的镜像：

```yml
initContainers:
      - name: install-cni
        image: rancher/coreos-flannel:v0.10.0 #第一处
        command:
        - cp
        args:
        - -f
        - /etc/kube-flannel/cni-conf.json
        - /etc/cni/net.d/10-flannel.conflist
        volumeMounts:
        - name: cni
          mountPath: /etc/cni/net.d
        - name: flannel-cfg
          mountPath: /etc/kube-flannel/
      containers:
      - name: kube-flannel
        image: rancher/coreos-flannel:v0.10.0 #第二处
        command:
        - /opt/bin/flanneld
        args:
        - --ip-masq
        - --kube-subnet-mgr
        - --iface=enp2s0f0
```


配置更新好后，创建flannel：

```shell
kubectl apply -f kube-flannel.yml
```

k8s kube-flannel启动输出：

```log
[root@kuber24 kubeadm-install]# kubectl apply -f kube-flannel.yml
clusterrole.rbac.authorization.k8s.io/flannel created
clusterrolebinding.rbac.authorization.k8s.io/flannel created
serviceaccount/flannel created
configmap/kube-flannel-cfg created
daemonset.extensions/kube-flannel-ds created
```


#### flannel 网络添加过程中的问题

再次查看所有namespace下的pods状态：

```shell
kubectl get pods --all-namespaces
```

我的还是Pending状态，如下：

```shell
[root@kuber24 kubeadm-install]# kubectl get pods --all-namespaces
NAMESPACE     NAME                              READY   STATUS    RESTARTS   AGE
kube-system   coredns-576cbf47c7-75gcc          0/1     Pending   0          132m
kube-system   coredns-576cbf47c7-v242w          0/1     Pending   0          132m
kube-system   etcd-kuber24                      1/1     Running   2          132m
kube-system   kube-apiserver-kuber24            1/1     Running   1          132m
kube-system   kube-controller-manager-kuber24   1/1     Running   2          132m
kube-system   kube-proxy-nd875                  1/1     Running   2          132m
kube-system   kube-scheduler-kuber24            1/1     Running   2          132m
[root@kuber24 kubeadm-install]#
```

查看flannel的DaemonSet资源情况：


```shell
kubectl get daemonset --all-namespaces
```

发现flannel的Desired 数量是0。


```shell
[root@kuber24 kubeadm-install]# kubectl get daemonset --all-namespaces
NAMESPACE     NAME              DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                   AGE
kube-system   kube-flannel-ds   0         0         0       0            0           beta.kubernetes.io/arch=amd64   53m
kube-system   kube-proxy        1         1         1       1            1           <none>                          133m
```

为什么`Desired 数量是0`呢？因为DaemonSet的运行是每个节点运行一个Pod，理论上应该有多少节点，Desired就是几。想到kubernetes中资源调度都是使用选择器`Selector`确定资源的，那么可能是Selector不是满足的。flannel的node selector是：

```yml
      nodeSelector:
        beta.kubernetes.io/arch: amd64
```

极有可能本节点定义中无`beta.kubernetes.io/arch: amd64`标签。

使用命令查看node的详细信息：

```shell
kubectl get nodes
kubectl describe node kuber24
```

结果输出如下：

```shell
[root@kuber24 kubeadm-install]# kubectl get nodes
NAME      STATUS     ROLES    AGE    VERSION
kuber24   NotReady   master   138m   v1.12.1
[root@kuber24 kubeadm-install]# kubectl describe node kuber24
Name:               kuber24
Roles:              master
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/os=linux
                    kubernetes.io/hostname=kuber24
                    node-role.kubernetes.io/master=
Annotations:        kubeadm.alpha.kubernetes.io/cri-socket: /var/run/dockershim.sock
                    node.alpha.kubernetes.io/ttl: 0
                    volumes.kubernetes.io/controller-managed-attach-detach: true
CreationTimestamp:  Thu, 18 Oct 2018 18:48:52 +0800
Taints:             node-role.kubernetes.io/master:NoSchedule
                    node.kubernetes.io/not-ready:NoSchedule
Unschedulable:      false
Conditions:
  Type             Status  LastHeartbeatTime                 LastTransitionTime                Reason                       Message
  ----             ------  -----------------                 ------------------                ------                       -------
  OutOfDisk        False   Thu, 18 Oct 2018 21:07:09 +0800   Thu, 18 Oct 2018 18:48:48 +0800   KubeletHasSufficientDisk     kubelet has sufficient disk space available
  MemoryPressure   False   Thu, 18 Oct 2018 21:07:09 +0800   Thu, 18 Oct 2018 18:48:48 +0800   KubeletHasSufficientMemory   kubelet has sufficient memory available
  DiskPressure     False   Thu, 18 Oct 2018 21:07:09 +0800   Thu, 18 Oct 2018 18:48:48 +0800   KubeletHasNoDiskPressure     kubelet has no disk pressure
  PIDPressure      False   Thu, 18 Oct 2018 21:07:09 +0800   Thu, 18 Oct 2018 18:48:48 +0800   KubeletHasSufficientPID      kubelet has sufficient PID available
  Ready            False   Thu, 18 Oct 2018 21:07:09 +0800   Thu, 18 Oct 2018 18:48:48 +0800   KubeletNotReady              runtime network not ready: NetworkReady=false reason:NetworkPluginNotReady message:docker: network plugin is not ready: cni config uninitialized
Addresses:
  InternalIP:  10.20.13.24
  Hostname:    kuber24
Capacity:
 attachable-volumes-azure-disk:  16
 cpu:                            16
 ephemeral-storage:              51175Mi
 hugepages-1Gi:                  0
 hugepages-2Mi:                  0
 memory:                         32775684Ki
 pods:                           110
Allocatable:
 attachable-volumes-azure-disk:  16
 cpu:                            16
 ephemeral-storage:              48294789041
 hugepages-1Gi:                  0
 hugepages-2Mi:                  0
 memory:                         32673284Ki
 pods:                           110
System Info:
 Machine ID:                 f5d4a7c028db41a29816c49b10a07950
 System UUID:                49434D53-0200-9029-2500-29902500A3D7
 Boot ID:                    8330549a-cfbf-49fa-a944-a4747cb90ad5
 Kernel Version:             3.10.0-862.11.6.el7.x86_64
 OS Image:                   CentOS Linux 7 (Core)
 Operating System:           linux
 Architecture:               amd64
 Container Runtime Version:  docker://1.13.1
 Kubelet Version:            v1.12.1
 Kube-Proxy Version:         v1.12.1
PodCIDR:                     10.1.0.0/24
Non-terminated Pods:         (5 in total)
  Namespace                  Name                               CPU Requests  CPU Limits  Memory Requests  Memory Limits
  ---------                  ----                               ------------  ----------  ---------------  -------------
  kube-system                etcd-kuber24                       0 (0%)        0 (0%)      0 (0%)           0 (0%)
  kube-system                kube-apiserver-kuber24             250m (1%)     0 (0%)      0 (0%)           0 (0%)
  kube-system                kube-controller-manager-kuber24    200m (1%)     0 (0%)      0 (0%)           0 (0%)
  kube-system                kube-proxy-nd875                   0 (0%)        0 (0%)      0 (0%)           0 (0%)
  kube-system                kube-scheduler-kuber24             100m (0%)     0 (0%)      0 (0%)           0 (0%)
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource                       Requests   Limits
  --------                       --------   ------
  cpu                            550m (3%)  0 (0%)
  memory                         0 (0%)     0 (0%)
  attachable-volumes-azure-disk  0          0
Events:
  Type     Reason             Age                From                 Message
  ----     ------             ----               ----                 -------
  Warning  ContainerGCFailed  16m (x7 over 22m)  kubelet, kuber24     rpc error: code = Unknown desc = Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
  Normal   Starting           15m                kube-proxy, kuber24  Starting kube-proxy.
```

发现此Node的labels中包含此label。那还可能是什么原因呢？

一番搜索后，发现：[https://serverfault.com/questions/933428/kubernetes-flannel-daemonset-not-starting-clean-ubuntu-16-and-18](https://serverfault.com/questions/933428/kubernetes-flannel-daemonset-not-starting-clean-ubuntu-16-and-18)

原因是：创建flannel pod的配置文件中，daemonset的tolerations限制的过于严格，导致flannel pod不能被正常调度，通过将tolerations限制放宽，使得flannel pod可以正常调度。关于toleration的更多细节参考：[kubernetes toleration说明](https://kubernetes.io/zh/docs/concepts/configuration/taint-and-toleration/)

通过查看上述node的详细描述信息，发现node有两个taint，分别是：

1. `node-role.kubernetes.io/master:NoSchedule`
2. `node.kubernetes.io/not-ready:NoSchedule`

而此时kube-flannel的toleration是：

```yml
    tolerations:
      - key: node-role.kubernetes.io/master
        operator: Exists
        effect: NoSchedule
```

这个tolerations仅能容忍`node-role.kubernetes.io/master:NoSchedule`，不能容忍`node.kubernetes.io/not-ready:NoSchedule`所以flannel pod不能被正常的调度。


使用

```shell
kubectl patch daemonset kube-flannel-ds \
  --namespace=kube-system \
  --patch='{"spec":{"template":{"spec":{"tolerations":[{"key": "node-role.kubernetes.io/master", "operator": "Exists", "effect": "NoSchedule"},{"effect":"NoSchedule","operator":"Exists"}]}}}}'
```

上述方法添加了一个无`key`的toleration，表示该toleration **容忍任意key**。

解决问题。

再次获取pods信息，如下：


```shell
[root@kuber24 ~]# kubectl get pods --all-namespaces
NAMESPACE     NAME                              READY   STATUS    RESTARTS   AGE
kube-system   coredns-576cbf47c7-75gcc          1/1     Running   0          15h
kube-system   coredns-576cbf47c7-v242w          1/1     Running   0          15h
kube-system   etcd-kuber24                      1/1     Running   2          15h
kube-system   kube-apiserver-kuber24            1/1     Running   1          15h
kube-system   kube-controller-manager-kuber24   1/1     Running   2          15h
kube-system   kube-flannel-ds-gwcj5             1/1     Running   0          12h
kube-system   kube-proxy-nd875                  1/1     Running   2          15h
kube-system   kube-scheduler-kuber24            1/1     Running   2          15h
```




## 安装Node节点

**安装node节点前，需要先执行环境准备章节的所有步骤。**

使用之前的ansible playbook 即可，注意playbook的`hosts`配置。

### 准备docker镜像



```shell
#!/bin/bash
images=(kube-proxy-amd64:v1.12.1 pause-amd64:3.1)
for imageName in ${images[@]} ; do
  docker pull mirrorgooglecontainers/$imageName
  if [[ $imageName =~ "amd64" ]]; then
    docker tag mirrorgooglecontainers/$imageName "k8s.gcr.io/${imageName//-amd64/}"
  else
    docker tag mirrorgooglecontainers/$imageName k8s.gcr.io/$imageName
  fi
  # docker rmi mirrorgooglecontainers/$imageName
done
```

### 加入集群

依据kubeadm init的初始化后的结果提示，运行命令：

```shell
kubeadm join 10.20.13.24:6443 --token gnq0ex.j4wqxy6o89f7tl1a --discovery-token-ca-cert-hash sha256:c59abe1944573cd9568c45e8d29cec6c9201348d707633c04fbb3ccb7036f851
```


> ⚠️注意：
> 1. 此处依据前面的**kubeadm init的输出提示**来操作。
> 2. master 节点默认已经加入到集群了，不用做此操作。


查看节点状态，可能会为：

```shell
[root@kuber24 playbooks]# kubectl get nodes
NAME      STATUS     ROLES    AGE   VERSION
kuber24   Ready      master   23h   v1.12.1
kuber25   NotReady   <none>   14s   v1.12.1
kuber26   NotReady   <none>   14s   v1.12.1
kuber27   NotReady   <none>   13s   v1.12.1
```

等待一段时间后（此时在创建flannel网络），会自动变为READY：


```shell
[root@kuber24 playbooks]# kubectl get nodes
NAME      STATUS   ROLES    AGE     VERSION
kuber24   Ready    master   23h     v1.12.1
kuber25   Ready    <none>   3m41s   v1.12.1
kuber26   Ready    <none>   3m41s   v1.12.1
kuber27   Ready    <none>   3m40s   v1.12.1
```

查看此时的集群PODS情况：


```shell
[root@kuber24 playbooks]# kubectl get pods --all-namespaces -o wide
NAMESPACE     NAME                              READY   STATUS    RESTARTS   AGE     IP            NODE      NOMINATED NODE
kube-system   coredns-576cbf47c7-75gcc          1/1     Running   0          23h     10.1.0.3      kuber24   <none>
kube-system   coredns-576cbf47c7-v242w          1/1     Running   0          23h     10.1.0.2      kuber24   <none>
kube-system   etcd-kuber24                      1/1     Running   2          23h     10.20.13.24   kuber24   <none>
kube-system   kube-apiserver-kuber24            1/1     Running   1          23h     10.20.13.24   kuber24   <none>
kube-system   kube-controller-manager-kuber24   1/1     Running   2          23h     10.20.13.24   kuber24   <none>
kube-system   kube-flannel-ds-6hqc4             1/1     Running   0          5m36s   10.20.13.25   kuber25   <none>
kube-system   kube-flannel-ds-bs4b7             1/1     Running   0          5m35s   10.20.13.27   kuber27   <none>
kube-system   kube-flannel-ds-gwcj5             1/1     Running   0          20h     10.20.13.24   kuber24   <none>
kube-system   kube-flannel-ds-tmsbc             1/1     Running   0          5m36s   10.20.13.26   kuber26   <none>
kube-system   kube-proxy-fqm89                  1/1     Running   0          5m35s   10.20.13.27   kuber27   <none>
kube-system   kube-proxy-nd875                  1/1     Running   2          23h     10.20.13.24   kuber24   <none>
kube-system   kube-proxy-qsf9z                  1/1     Running   0          5m36s   10.20.13.25   kuber25   <none>
kube-system   kube-proxy-ww8x7                  1/1     Running   0          5m36s   10.20.13.26   kuber26   <none>
kube-system   kube-scheduler-kuber24            1/1     Running   2          23h     10.20.13.24   kuber24   <none>
```




## 问题总结


### flannel pod desired=0

参考本文档的：flannel 网络添加过程中的问题 小结。

### 时间同步问题

错误信息：

```
[discovery] Failed to request cluster info, will try again: [Get https://192.168.0.101:6443/api/v1/namespaces/kube-public/configmaps/cluster-info: x509: certificate has expired or is not yet valid]
```

解决：

```shell
ntpdate ntp1.aliyun.com
```