# The dev environment: same Python + libraries as production, plus dev tools.
FROM mcr.microsoft.com/devcontainers/python:3.12

COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt pytest httpx ipython \
    && rm /tmp/requirements.txt
