# Docker Containers: From Laptop to AWS

Demo code is in this folder. Every command runs from a Linux shell (Ubuntu on WSL2 here).

---

## 1. What is a container?

One machine and one kernel. Each container brings **its own environment**: its own libraries, runtime versions and files.

```mermaid
flowchart TB
    subgraph C1["Container A"]
        A1["App A"] --> L1["Python 3.12<br/>scikit-learn 1.5"]
    end
    subgraph C2["Container B"]
        A2["App B"] --> L2["Python 3.9<br/>pandas 1.3"]
    end
    subgraph C3["Container C"]
        A3["App C"] --> L3["Node 20<br/>Express"]
    end
    C1 & C2 & C3 --> E["Docker Engine"]
    E --> K["Shared Linux kernel (host OS)"]
    K --> H["Hardware"]
```

**Compared with a virtual machine:** each VM runs a whole guest operating system. A container shares the host's kernel, so it starts in milliseconds and takes up megabytes instead of gigabytes.

```mermaid
flowchart LR
    subgraph VM["Virtual machines"]
        direction TB
        v1["App"] --> g1["Guest OS"]
        v2["App"] --> g2["Guest OS"]
        g1 & g2 --> hv["Hypervisor"]
    end
    subgraph CT["Containers"]
        direction TB
        c1["App + libs"]
        c2["App + libs"]
        c1 & c2 --> de["Docker Engine"]
    end
```

**Three words to know**

| Term | Meaning | Analogy |
|---|---|---|
| Dockerfile | Instructions for building an image | Sheet music |
| Image | Built snapshot that can't change | A recording: fixed, and copied anywhere |
| Container | A running instance of an image | Someone playing the recording |

A million people can play the same recording at once, and playing it never changes the recording. In our demo, the recording is the trained model.

```mermaid
flowchart LR
    D["Dockerfile"] -- "docker build" --> I["Image"]
    I -- "docker push" --> R["Registry<br/>(Docker Hub / ECR)"]
    R -- "docker pull" --> I2["Image"]
    I2 -- "docker run" --> C["Container"]
```

---

## 2. How it's typically deployed at customers

<!-- Personalize: swap in the customer names / stacks you've actually seen -->

Across customers, the pattern is almost always the same pipeline. Only the last box changes.

```mermaid
flowchart LR
    Dev["Developer<br/>git push"] --> CI["CI pipeline<br/>(GitHub Actions /<br/>GitLab / Jenkins)"]
    CI -- "build + test<br/>image" --> Reg["Private registry<br/>(ECR / ACR / Artifactory)"]
    Reg --> T1["Lambda"]
    Reg --> T2["ECS / Fargate"]
    Reg --> T3["Kubernetes<br/>(EKS / AKS / OpenShift)"]
```

The usual setup:
- **The image is the unit of release.** The same image goes to dev, staging and prod. Only configuration changes, through environment variables and secrets.
- **The registry is private**, and images are often scanned for vulnerabilities before they can be deployed.
- **Infrastructure is code** (Terraform or CDK), not people clicking around in the AWS console.
- **ML models specifically:** the model file is either baked into the image (simple, as in this demo) or pulled from S3 or a model registry at startup (better for big or frequently updated models).

### The demo: wrap a model in a container

Real data: Fisher's 1936 **Iris** measurements (150 flowers, bundled with scikit-learn). The model predicts the species from petal and sepal size. It's a deliberately trivial model.

```mermaid
flowchart LR
    subgraph Build["docker build (multi-stage)"]
        S1["Stage 1: train<br/>train.py → model.joblib"] --> S2["Stage 2: serve<br/>FastAPI + model.joblib"]
    end
    S2 --> Img["iris-api image"]
    Img --> Run["docker run -p 8080:8080"]
    User["curl /predict"] --> Run
```

Files: `model/train.py`, `app/main.py`, `Dockerfile`

```bash
docker build -t iris-api .
docker run --rm -p 8080:8080 iris-api

curl -s -X POST localhost:8080/predict \
  -H "Content-Type: application/json" \
  -d '{"sepal_length":5.1,"sepal_width":3.5,"petal_length":1.4,"petal_width":0.2}'
# {"species":"setosa","confidence":0.98}
```

> Talking point: there's no Python on the host. The build trained the model.

---

## 3. Deploying to AWS: one image, three targets

Every target starts the same way: push the image to ECR (`deploy/push-to-ecr.sh`).

```mermaid
flowchart TB
    Img["iris-api image"] --> ECR["Amazon ECR"]
    ECR --> L["Lambda<br/>runs per request<br/>pay per call"]
    ECR --> E["ECS Fargate<br/>always-on tasks<br/>AWS manages servers"]
    ECR --> K["EKS (Kubernetes)<br/>pods on a cluster<br/>you manage the platform"]
```

| | Lambda | ECS Fargate | Kubernetes (EKS) |
|---|---|---|---|
| Best for | Spiky / low traffic | Steady web services | Many services, platform teams |
| Scales to zero | Yes | No | No (not by default) |
| Cold start | Yes (seconds) | No | No |
| Ops effort | Lowest | Low | Highest |
| Demo file | `deploy/lambda/` | `deploy/ecs/` | `deploy/k8s/iris.yaml` |

### Lambda
Uses AWS's Lambda base image and a small `handler.py`, with the same `predict()` function as before.
```bash
docker build -f deploy/lambda/Dockerfile -t iris-lambda .
docker run --rm -p 9000:8080 iris-lambda          # built-in local Lambda emulator
curl -s localhost:9000/2015-03-31/functions/function/invocations \
  -d '{"sepal_length":6.7,"sepal_width":3.0,"petal_length":5.2,"petal_width":2.3}'
# real deploy: LAMBDA_ROLE_ARN=... ./deploy/lambda/deploy.sh
```

### ECS Fargate
A **task definition** (which image, CPU and memory, port, health check) plus a **service** ("keep 2 of these running").
```bash
SUBNET=subnet-xxx SG=sg-xxx ./deploy/ecs/deploy.sh
```

### Kubernetes
A **Deployment** ("run 3 replicas, restart them if they fail") plus a **Service** (one stable address in front of them).
```mermaid
flowchart LR
    U["Traffic"] --> S["Service iris-api"]
    S --> P1["Pod"] & P2["Pod"] & P3["Pod"]
```
```bash
kind create cluster                        # local cluster, runs in Docker itself
kind load docker-image iris-api:latest
kubectl apply -f deploy/k8s/iris.yaml
kubectl port-forward svc/iris-api 8080:80
```

---

## 4. A dev environment that works for everyone

The problem: *"works on my machine."* The fix: ship the **environment** along with the code.

```mermaid
flowchart LR
    subgraph Laptop["Anyone's laptop (Win / Mac / Linux)"]
        Code["Your code folder"]
        Editor["VS Code / terminal"]
    end
    subgraph DC["Dev container"]
        Py["Python 3.12 + exact libs<br/>pytest, tools"]
    end
    Code <-- "mounted (live edits)" --> DC
    Editor --> DC
```

The code stays on your machine and the container supplies everything else. A new teammate needs only **Docker + git**.

**Option A: VS Code Dev Containers** (`.devcontainer/`)
1. Open the folder in VS Code.
2. Click "Reopen in Container".
3. A terminal opens inside the environment, and the model is already trained.

**Option B: plain Docker** (`dev.sh`)
```bash
./dev.sh                       # shell inside the environment
./dev.sh python -m pytest      # run the tests
./dev.sh uvicorn app.main:app --host 0.0.0.0 --port 8080 --reload
```

---

## Recap

```mermaid
flowchart LR
    A["Dev container<br/>(same env for all)"] --> B["Dockerfile<br/>→ image"]
    B --> C["CI + registry"]
    C --> D["Lambda / ECS / K8s"]
```

One definition of the environment, from the first line of code all the way to production.
