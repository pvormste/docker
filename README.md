# Docker Image with go compiler and tools

## Dockerhub: https://hub.docker.com/r/pvormste/docker-go

### Usage

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

