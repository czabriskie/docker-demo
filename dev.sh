#!/usr/bin/env bash
# No VS Code? Same dev environment, plain Docker.
# Your code stays on your machine; the container supplies Python + libraries.
#   ./dev.sh                      -> interactive shell
#   ./dev.sh python model/train.py
set -euo pipefail
docker build -q -t iris-dev -f .devcontainer/Dockerfile . >/dev/null
docker run --rm -it \
  -v "$PWD":/workspace -w /workspace \
  -p 8080:8080 \
  iris-dev "${@:-bash}"
