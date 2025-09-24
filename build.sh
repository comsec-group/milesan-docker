set -e
IMAGE_TAG=milesan-docker-ccs
docker build --build-arg COMPILE_VERILATOR_TARGETS=$COMPILE_VERILATOR_TARGETS -f Dockerfile -t $IMAGE_TAG .
