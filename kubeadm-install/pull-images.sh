#!/bin/bash
images=(kube-proxy-amd64:v1.12.1 kube-scheduler-amd64:v1.12.1 kube-controller-manager-amd64:v1.12.1 kube-apiserver-amd64:v1.12.1
etcd-amd64:3.2.24 coredns:1.1.3 pause-amd64:3.1 kubernetes-dashboard-amd64:v1.10.0 k8s-dns-sidecar-amd64:1.14.13 k8s-dns-kube-dns-amd64:1.14.13 
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
