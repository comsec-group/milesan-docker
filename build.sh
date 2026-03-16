set -e
IMAGE_TAG=milesan-image-pub
QUESTASIM=/usr/local/questa-2022-03/
docker build  --build-context questasim=$QUESTASIM -f Dockerfile -t $IMAGE_TAG  .
