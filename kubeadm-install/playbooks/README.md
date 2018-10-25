# ansible playbooks

主要包含的playbook：
* `env.yml`: 安装master和node节点公共的基础环境，防火墙设置，swap分区设置等
* `node_images.yml`: 拉取node节点需要的镜像
* `node_images_with_dashboard.yml`:拉取node节点需要的镜像，包括dashboard 和heapster 相关的镜像
* `node_join_cluster.yml`: node节点加入kubernetes集群
* `rm-kube.yml`: 卸载使用yum 安装的kubernetesrpm包
* `start_docker.yml`: kubernetes集群启动docker服务并作为开机启动
* `stop_prev_service.yml`: 停止直接在物理机上安装的kubernetes服务。