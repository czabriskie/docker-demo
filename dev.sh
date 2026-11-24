#!/usr/bin/env bash
# No VS Code? Same dev environment, plain Docker.
# Your code stays on your machine; the container supplies Python + libraries.
#   ./dev.sh                      -> interactive shell
#   ./dev.sh python -m pytest     -> run the tests
set -euo pipefail
cd "$(dirname "$0")"
docker build -q -t iris-dev -f .devcontainer/Dockerfile . >/dev/null

TTY=""
[ -t 0 ] && TTY="-it"

# Train the model on first use, then run whatever was asked (default: a shell)
docker run --rm $TTY \
  -v "$PWD":/workspace -w /workspace \
  -p 8080:8080 \
  iris-dev bash -c '[ -f artifacts/model.joblib ] || python model/train.py >/dev/null; exec "$@"' _ "${@:-bash}"
