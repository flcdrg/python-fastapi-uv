# Install uv
FROM python:3.13-slim AS builder
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Change the working directory to the `app` directory
WORKDIR /app

# Install dependencies
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --locked --no-install-project --no-editable

# Copy the project into the intermediate image
ADD . /app

# Sync the project
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-editable

RUN ls -al

FROM python:3.13-slim

RUN apt-get update && apt-get install -y libltdl7 libkrb5-3 libgssapi-krb5-2 && rm -rf /var/lib/apt/lists/*

RUN groupadd --system --gid 999 nonroot \
 && useradd --system --gid 999 --uid 999 --create-home nonroot

WORKDIR /app

# Copy the environment, but not the source code
COPY --from=builder --chown=nonroot:nonroot /app/.venv /app/.venv

# Copy the source code
COPY --from=builder --chown=nonroot:nonroot /app/main.py /app/main.py

# https://github.com/astral-sh/uv-docker-example/blob/main/Dockerfile
# Place executables in the environment at the front of the path
ENV PATH="/app/.venv/bin:$PATH"

# Reset the entrypoint, don't invoke `uv`
ENTRYPOINT []

# Use the non-root user to run our application
USER nonroot

# Run the FastAPI application by default
CMD ["fastapi", "run", "main.py", "--host", "0.0.0.0"]