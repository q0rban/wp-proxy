This repository is a boilerplate / scaffold to build a Docker image using CircleCI. It's primary purpose is to build
custom images for use with [https://www.tugboat.qa], but it would work for building any Docker image.

# Usage

1. Fork or duplicate this repository to your own repo.
2. Add the project to CircleCI.
3. In CircleCI, set up the `DOCKER_USER` and `DOCKER_PASS` environment variables with the Docker credentials that can push.
4. Modify the Makefile, specifically the `DESTINATION_DOCKER_IMAGE`, to point to your destination Docker image.
5. Modify the Dockerfile. Where possible, for building Docker images for use with [Tugboat](https://www.tugboat.qa), use one of the [official Tugboat images](https://docs.tugboat.qa/reference/tugboat-images/) to start.
6. Read through the .circleci/config.yml. Modify the cron schedule as desired.
6. Commit and push these changes. CircleCI should trigger an On Hold build, but you'll need to approve it.
7. Approve the On Hold job to run it immediately OR wait for your cron schedule to have CircleCI run it then.
