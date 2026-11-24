# Docker Containers Demo

A tiny ML model (Iris species predictor, real 1936 data) wrapped in a container, deployed three ways on AWS, plus a dev environment anyone can use.

- **Students:** start with [LAB.md](LAB.md)
- **Presentation:** [PRESENTATION.md](PRESENTATION.md)

```
model/train.py           train the model
app/main.py              HTTP API (FastAPI)
Dockerfile               build = train + serve
tests/                   one test
dev.sh                   dev environment via plain Docker
.devcontainer/           dev environment via VS Code
deploy/push-to-ecr.sh    push the image to AWS ECR
deploy/lambda/           run as AWS Lambda
deploy/ecs/              run on ECS Fargate
deploy/k8s/              run on Kubernetes
```

Quick start (needs only Docker):
```bash
docker build -t iris-api .
docker run --rm -p 8080:8080 iris-api
```
