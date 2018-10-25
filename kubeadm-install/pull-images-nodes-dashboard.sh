#!/bin/bash
images=(kube-proxy-amd64:v1.12.1 pause-amd64:3.1 kubernetes-dashboard-amd64:v1.10.0 heapster-grafana-amd64:v5.0.4 heapster-amd64:v1.5.4 heapster-influxdb-amd64:v1.5.2)
for imageName in ${images[@]} ; do
  docker pull mirrorgooglecontainers/$imageName
  if [[ $imageName =~ "amd64" ]]; then
    docker tag mirrorgooglecontainers/$imageName "k8s.gcr.io/${imageName//-amd64/}"
  else
    docker tag mirrorgooglecontainers/$imageName k8s.gcr.io/$imageName
  fi
  # docker rmi mirrorgooglecontainers/$imageName
done
