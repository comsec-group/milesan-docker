set -e
IMAGE_TAG=milesan-docker-ccs
docker build -f Dockerfile -t $IMAGE_TAG .
