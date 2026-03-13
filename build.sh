set -e
IMAGE_TAG=milesan-image-pub
docker build  -f Dockerfile -t $IMAGE_TAG  .
