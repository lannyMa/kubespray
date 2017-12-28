v1.9  20171228
## 所有机器swapoff -a ,否则报api启动不了
## 涉及到的修改的配置
```
inventory/group_vars/all.yml
inventory/group_vars/k8s-cluster.yml

roles/kubernetes/preinstall/tasks/verify-settings.yml
```

## run.sh里有运行命令

## kubespray(ansible)自动化安装k8s集群
```
- 最佳安装centos7

- 安装docker

- 规划3(n1  n2 n3)主2从(n4 n5)

- hosts

192.168.2.11 n1.ma.com n1
192.168.2.12 n2.ma.com n2
192.168.2.13 n3.ma.com n3
192.168.2.14 n4.ma.com n4
192.168.2.15 n5.ma.com n5
192.168.2.16 n6.ma.com n6

- 拉取镜像
docker pull lanny/gcr.io_google_containers_pause-amd64:3.0
docker pull lanny/gcr.io_google_containers_cluster-proportional-autoscaler-amd64:1.1.1
docker pull lanny/gcr.io_google_containers_k8s-dns-kube-dns-amd64:1.14.7
docker pull lanny/gcr.io_google_containers_k8s-dns-dnsmasq-nanny-amd64:1.14.7
docker pull lanny/gcr.io_google_containers_k8s-dns-sidecar-amd64:1.14.7
docker pull lanny/gcr.io_google_containers_kubernetes-dashboard-amd64:v1.7.1
docker pull lanny/gcr.io_google_containers_kubernetes-dashboard-init-amd64:v1.0.1
docker pull lanny/quay.io_coreos_hyperkube:v1.9.0_coreos.0

docker tag lanny/gcr.io_google_containers_pause-amd64:3.0 gcr.io/google_containers/pause-amd64:3.0
docker tag lanny/gcr.io_google_containers_cluster-proportional-autoscaler-amd64:1.1.1 gcr.io/google_containers/cluster-proportional-autoscaler-amd64:1.1.1
docker tag lanny/gcr.io_ google_containers_k8s-dns-kube-dns-amd64:1.14.7 gcr.io/google_containers/k8s-dns-kube-dns-amd64:1.14.7
docker tag lanny/gcr.io_google_containers_k8s-dns-dnsmasq-nanny-amd64:1.14.7 gcr.io/google_containers/k8s-dns-dnsmasq-nanny-amd64:1.14.7
docker tag lanny/gcr.io_google_containers_k8s-dns-sidecar-amd64:1.14.7 gcr.io/google_containers/k8s-dns-sidecar-amd64:1.14.7
docker tag lanny/gcr.io_google_containers_kubernetes-dashboard-amd64:v1.7.1 gcr.io/google_containers/kubernetes-dashboard-amd64:v1.7.1
docker tag lanny/gcr.io_google_containers_kubernetes-dashboard-init-amd64:v1.0.1 gcr.io/google_containers/kubernetes-dashboard-init-amd64:v1.0.1
docker tag lanny/quay.io_coreos_hyperkube:v1.9.0_coreos.0 quay.io/coreos/hyperkube:v1.9.0_coreos.0


- 安装完后查看镜像(用到的镜像)
nginx:1.13
quay.io/coreos/hyperkube:v1.9.0_coreos.0
gcr.io/google_containers/k8s-dns-sidecar-amd64:1.14.7
gcr.io/google_containers/k8s-dns-kube-dns-amd64:1.14.7
gcr.io/google_containers/k8s-dns-dnsmasq-nanny-amd64:1.14.7
quay.io/calico/node:v2.6.2
gcr.io/google_containers/kubernetes-dashboard-init-amd64:v1.0.1
quay.io/calico/cniv:1.11.0
gcr.io/google_containers/kubernetes-dashboard-amd64:v1.7.1
quay.io/calico/ctlv:1.6.1
quay.io/calico/routereflectorv:0.4.0
quay.io/coreos/etcdv:3.2.4
gcr.io/google_containers/cluster-proportional-autoscaler-amd64:1.1.1
gcr.io/google_containers/pause-amd64:3.0



- kubespray生成配置所需的环境(python3 ansible) Ansible v2.4 (or newer) Jinja 2.9 (or newer) 
yum install python34 python34-pip python-pip  python-netaddr -y
cd
mkdir .pip
cd .pip
cat > pip.conf <<EOF
[global]
index-url = http://mirrors.aliyun.com/pypi/simple/

[install]
trusted-host=mirrors.aliyun.com
EOF

yum install gcc libffi-devel python-devel openssl-devel -y
pip install  Jinja2-2.10-py2.py3-none-any.whl # https://pypi.python.org/pypi/Jinja2
pip install cryptography
pip install ansible



- 克隆
git clone https://github.com/kubernetes-incubator/kubespray.git


- 修改配置

1. 使docker能pull gcr的镜像
vim inventory/group_vars/all.yml
2 bootstrap_os: centos
95 http_proxy: "http://192.168.1.88:1080/"

2. 如果vm内存<=1G,如果>=3G,则无需修改
vim roles/kubernetes/preinstall/tasks/verify-settings.yml 
52 - name: Stop if memory is too small for masters
53   assert:
54     that: ansible_memtotal_mb <= 1500
55   ignore_errors: "{{ ignore_assert_errors }}"
56   when: inventory_hostname in groups['kube-master']
57 
58 - name: Stop if memory is too small for nodes
59   assert:
60     that: ansible_memtotal_mb <= 1024              
61   ignore_errors: "{{ ignore_assert_errors }}"


3. 修改swap,
vim roles/download/tasks/download_container.yml
 75 - name: Stop if swap enabled
 76   assert:
 77     that: ansible_swaptotal_mb == 0         
 78   when: kubelet_fail_swap_on|default(false)

所有机器执行: 关闭swap
swapoff -a
[root@n1 kubespray]# free -m
              total        used        free      shared  buff/cache   available
Mem:           2796         297        1861           8         637        2206
Swap:             0           0           0  #这栏为0,表示关闭

- 生成 kubespray配置,开始ansible安装k8s之旅(非常用时间,大到1h,小到20min)
cd kubespray
IPS=(192.168.2.11 192.168.2.12 192.168.2.13 192.168.2.14 192.168.2.15)
CONFIG_FILE=inventory/inventory.cfg python3 contrib/inventory_builder/inventory.py ${IPS[@]}
ansible-playbook -i inventory/inventory.cfg cluster.yml -b -v --private-key=~/.ssh/id_rsa


- 我的inventory.cfg, 我不想让node和master混在一起手动改了下
[root@n1 kubespray]# cat inventory/inventory.cfg 
[all]
node1 	 ansible_host=192.168.2.11 ip=192.168.2.11
node2 	 ansible_host=192.168.2.12 ip=192.168.2.12
node3 	 ansible_host=192.168.2.13 ip=192.168.2.13
node4 	 ansible_host=192.168.2.14 ip=192.168.2.14
node5 	 ansible_host=192.168.2.15 ip=192.168.2.15

[kube-master]
node1 	 
node2 	 
node3

[kube-node] 	 
node4 	 
node5 	 

[etcd]
node1 	 
node2 	 
node3 	 

[k8s-cluster:children]
kube-node 	 
kube-master 	 

[calico-rr]
```

## 遇到的问题wait for the apiserver to be running

```
ansible-playbook -i inventory/inventory.ini cluster.yml -b -v --private-key=~/.ssh/id_rsa
...
<!-- We recommend using snippets services like https://gist.github.com/ etc. -->
RUNNING HANDLER [kubernetes/master : Master | wait for the apiserver to be running] ***
Thursday 23 March 2017  10:46:16 +0800 (0:00:00.468)       0:08:32.094 ******** 
FAILED - RETRYING: HANDLER: kubernetes/master : Master | wait for the apiserver to be running (10 retries left).
FAILED - RETRYING: HANDLER: kubernetes/master : Master | wait for the apiserver to be running (10 retries left).
FAILED - RETRYING: HANDLER: kubernetes/master : Master | wait for the apiserver to be running (9 retries left).
FAILED - RETRYING: HANDLER: kubernetes/master : Master | wait for the apiserver to be running (9 retries left).
FAILED - RETRYING: HANDLER: kubernetes/master : Master | wait for the apiserver to be running (8 retries left).
FAILED - RETRYING: HANDLER: kubernetes/master : Master | wait for the apiserver to be running (8 retries left).
FAILED - RETRYING: HANDLER: kubernetes/master : Master | wait for the apiserver to be running (7 retries left).
FAILED - RETRYING: HANDLER: kubernetes/master : Master | wait for the apiserver to be running (7 retries left).
FAILED - RETRYING: HANDLER: kubernetes/master : Master | wait for the apiserver to be running (6 retries left).
FAILED - RETRYING: HANDLER: kubernetes/master : Master | wait for the apiserver to be running (6 retries left).
FAILED - RETRYING: HANDLER: kubernetes/master : Master | wait for the apiserver to be running (5 retries left).
FAILED - RETRYING: HANDLER: kubernetes/master : Master | wait for the apiserver to be running (5 retries left).
FAILED - RETRYING: HANDLER: kubernetes/master : Master | wait for the apiserver to be running (4 retries left).
FAILED - RETRYING: HANDLER: kubernetes/master : Master | wait for the apiserver to be running (4 retries left).
FAILED - RETRYING: HANDLER: kubernetes/master : Master | wait for the apiserver to be running (3 retries left).
FAILED - RETRYING: HANDLER: kubernetes/master : Master | wait for the apiserver to be running (3 retries left).
FAILED - RETRYING: HANDLER: kubernetes/master : Master | wait for the apiserver to be running (2 retries left).
FAILED - RETRYING: HANDLER: kubernetes/master : Master | wait for the apiserver to be running (2 retries left).
FAILED - RETRYING: HANDLER: kubernetes/master : Master | wait for the apiserver to be running (1 retries left).
FAILED - RETRYING: HANDLER: kubernetes/master : Master | wait for the apiserver to be running (1 retries left).
fatal: [node1]: FAILED! => {"attempts": 10, "changed": false, "content": "", "failed": true, "msg": "Status code was not [200]: Request failed: <urlopen error [Errno 111] Connection refused>", "redirected": false, "status": -1, "url": "http://localhost:8080/healthz"}
fatal: [node2]: FAILED! => {"attempts": 10, "changed": false, "content": "", "failed": true, "msg": "Status code was not [200]: Request failed: <urlopen error [Errno 111] Connection refused>", "redirected": false, "status": -1, "url": "http://localhost:8080/healthz"}
        to retry, use: --limit @/home/dev_dean/kargo/cluster.retry
```

解决: 所有节点关闭swap
```
swapoff -a
```

![](http://images2017.cnblogs.com/blog/806469/201712/806469-20171228000459597-535895199.png)

![](http://images2017.cnblogs.com/blog/806469/201712/806469-20171228000727816-1913513533.png)



## 快捷命令
```
alias kk='kubectl get pod --all-namespaces -o wide --show-labels'
alias ks='kubectl get svc --all-namespaces -o wide'
alias kss='kubectl get svc --all-namespaces -o wide --show-labels'
alias kd='kubectl get deploy --all-namespaces -o wide'
alias wk='watch kubectl get pod --all-namespaces -o wide --show-labels'
alias kv='kubectl get pv -o wide'
alias kvc='kubectl get pvc -o wide --all-namespaces --show-labels'
alias kbb='kubectl run -it --rm --restart=Never busybox --image=busybox sh'
alias kbbc='kubectl run -it --rm --restart=Never curl --image=appropriate/curl sh'
alias kd='kubectl get deployment --all-namespaces --show-labels'
alias kcm='kubectl get cm --all-namespaces -o wide'
alias kin='kubectl get ingress --all-namespaces -o wide' 
```


## kubespray的默认启动参数
```
ps -ef|egrep  "apiserver|controller-manager|scheduler"


/hyperkube apiserver \
--advertise-address=192.168.2.11 \
--etcd-servers=https://192.168.2.11:2379,https://192.168.2.12:2379,https://192.168.2.13:2379 \
--etcd-quorum-read=true \
--etcd-cafile=/etc/ssl/etcd/ssl/ca.pem \
--etcd-certfile=/etc/ssl/etcd/ssl/node-node1.pem \
--etcd-keyfile=/etc/ssl/etcd/ssl/node-node1-key.pem \
--insecure-bind-address=127.0.0.1 \
--bind-address=0.0.0.0 \
--apiserver-count=3 \
--admission-control=Initializers,NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,ValidatingAdmissionWebhook,ResourceQuota \
--service-cluster-ip-range=10.233.0.0/18 \
--service-node-port-range=30000-32767 \
--client-ca-file=/etc/kubernetes/ssl/ca.pem \
--profiling=false \
--repair-malformed-updates=false \
--kubelet-client-certificate=/etc/kubernetes/ssl/node-node1.pem \
--kubelet-client-key=/etc/kubernetes/ssl/node-node1-key.pem \
--service-account-lookup=true \
--tls-cert-file=/etc/kubernetes/ssl/apiserver.pem \
--tls-private-key-file=/etc/kubernetes/ssl/apiserver-key.pem \
--proxy-client-cert-file=/etc/kubernetes/ssl/apiserver.pem \
--proxy-client-key-file=/etc/kubernetes/ssl/apiserver-key.pem \
--service-account-key-file=/etc/kubernetes/ssl/apiserver-key.pem \
--secure-port=6443 \
--insecure-port=8080 
--storage-backend=etcd3 \
--runtime-config=admissionregistration.k8s.io/v1alpha1 --v=2 \
--allow-privileged=true \
--anonymous-auth=False \
--authorization-mode=Node,RBAC \
--feature-gates=Initializers=False \
PersistentLocalVolumes=False


/hyperkube controller-manager \
--kubeconfig=/etc/kubernetes/kube-controller-manager-kubeconfig.yaml \
--leader-elect=true \
--service-account-private-key-file=/etc/kubernetes/ssl/apiserver-key.pem \
--root-ca-file=/etc/kubernetes/ssl/ca.pem \
--cluster-signing-cert-file=/etc/kubernetes/ssl/ca.pem \
--cluster-signing-key-file=/etc/kubernetes/ssl/ca-key.pem \
--enable-hostpath-provisioner=false \
--node-monitor-grace-period=40s \
--node-monitor-period=5s \
--pod-eviction-timeout=5m0s \
--profiling=false \
--terminated-pod-gc-threshold=12500 \
--v=2 \
--use-service-account-credentials=true \
--feature-gates=Initializers=False \
PersistentLocalVolumes=False


/hyperkube scheduler \
--leader-elect=true \
--kubeconfig=/etc/kubernetes/kube-scheduler-kubeconfig.yaml \
--profiling=false --v=2 \
--feature-gates=Initializers=False \
PersistentLocalVolumes=False

```



```

/usr/local/bin/kubelet \
--logtostderr=true --v=2 \
--address=192.168.2.14 \
--node-ip=192.168.2.14 \
--hostname-override=node4 \
--allow-privileged=true \
--pod-manifest-path=/etc/kubernetes/manifests \
--cadvisor-port=0 \
--pod-infra-container-image=gcr.io/google_containers/pause-amd64:3.0 \
--node-status-update-frequency=10s \
--docker-disable-shared-pid=True \
--client-ca-file=/etc/kubernetes/ssl/ca.pem \
--tls-cert-file=/etc/kubernetes/ssl/node-node4.pem \
--tls-private-key-file=/etc/kubernetes/ssl/node-node4-key.pem \
--anonymous-auth=false \
--cgroup-driver=cgroupfs \
--cgroups-per-qos=True \
--fail-swap-on=True \
--enforce-node-allocatable= \
--cluster-dns=10.233.0.3 \
--cluster-domain=cluster.local \
--resolv-conf=/etc/resolv.conf \
--kubeconfig=/etc/kubernetes/node-kubeconfig.yaml \
--require-kubeconfig \
--kube-reserved cpu=100m,memory=256M \
--node-labels=node-role.kubernetes.io/node=true \
--feature-gates=Initializers=False,PersistentLocalVolumes=False \
--network-plugin=cni --cni-conf-dir=/etc/cni/net.d \
--cni-bin-dir=/opt/cni/bin


ps -ef|grep kube-porxy
hyperkube proxy --v=2 \
    --kubeconfig=/etc/kubernetes/kube-proxy-kubeconfig.yaml\
    --bind-address=192.168.2.14 \
    --cluster-cidr=10.233.64.0/18 \
    --proxy-mode=iptables

```