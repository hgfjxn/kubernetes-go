#!/bin/bash
holder=jay1991115
images=(tiller:v2.11.0 )
for imageName in ${images[@]} ; do
  docker pull $holder/$imageName
  if [[ $imageName =~ "amd64" ]]; then
    docker tag $holder/$imageName "gcr.io/kubernetes-helm/${imageName//-amd64/}"
  else
    docker tag $holder/$imageName gcr.io/kubernetes-helm/$imageName
  fi
  # docker rmi mirrorgooglecontainers/$imageName
done
