# Build from the repo root:
#   docker build -f deploy/lambda/Dockerfile -t iris-lambda .
FROM python:3.12-slim AS train
WORKDIR /src
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY model/ model/
RUN MODEL_DIR=/artifacts python model/train.py

# AWS's own Lambda base image: includes the runtime interface + a local emulator
FROM public.ecr.aws/lambda/python:3.12
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app/ ${LAMBDA_TASK_ROOT}/app/
COPY deploy/lambda/handler.py ${LAMBDA_TASK_ROOT}/
COPY --from=train /artifacts/model.joblib ${LAMBDA_TASK_ROOT}/artifacts/model.joblib
ENV MODEL_PATH=${LAMBDA_TASK_ROOT}/artifacts/model.joblib
CMD ["handler.handler"]
