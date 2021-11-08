#! /bin/bash

TAG="$1"
IMAGE_NAME="miarka-ansible"

# if a tag is not specified, use the git commit hash or "latest" if the git commit hash could not be determined
if [[ -z "${TAG}" ]]
then
  TAG="$(git rev-parse --short HEAD || echo "latest")"
fi

# build the docker image
docker build \
  -t "${IMAGE_NAME}:${TAG}" \
  "$(dirname "$0")"

# build the singularity image from the docker image
singularity build \
  -F \
  "${IMAGE_NAME}.sif" \
  "docker-daemon:${IMAGE_NAME}:${TAG}"
