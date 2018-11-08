#!/bin/bash
owner=$1
if [ -z $owner ]; then
  echo "please input docker username"
  exit
fi
cat /dev/null > images.list
echo "docker hub login"
docker login -u $owner
images=`docker images --format "{{.Repository}}:{{.Tag}}"`
for imageName in ${images[@]} ; do
  image=${imageName##*/}
  echo "push to "$owner/$image
  docker tag $imageName $owner/$image
  docker push $owner/$image
  docker rmi $owner/$image
  echo $imageName >> images.list
 done
 echo -e '\r\n\r\nSuccess!\r\n\r\n'
