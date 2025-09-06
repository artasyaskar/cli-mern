#!/usr/bin/env bash
set -euo pipefail

# Get the root directory of the project
ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT_DIR"

echo "--- Running verification for devops-docker-healthcheck ---"

# This task's verification is a shell script that performs static checks.
# No services or dependencies are needed.
bash "tasks/devops-docker-healthcheck/tests/docker.setup.test.sh"

echo "✅ devops-docker-healthcheck verified"
