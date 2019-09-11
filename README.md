# Docker Image with go compiler and tools

This branch can create a docker image by using the official docker image Dockerfile and adding the go compiler and tools.
So you can compile and run go programs with this image and also use docker with docker:dind (for ci pipelines).

## Dockerhub: https://hub.docker.com/r/pvormste/docker-go

### How to create the docker image

Simply run the `build-go.sh` shell script.  

You can also customize the script to your needs (e.g. change go version or image name).

### Example Usage

#### Gitlab

```yml
"integration tests":
  stage: test
  image: pvormste/docker-go:1.12
  services:
    - docker:dind
  script:
    - go test -tags integration -v ./... 2>&1 | go-junit-report > report.xml
  artifacts:
    reports:
      junit: report.xml

```

