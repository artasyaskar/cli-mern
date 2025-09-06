#!/usr/bin/env bash
set -euo pipefail

# Get the root directory of the project
ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT_DIR"

# Function to clean up services on script exit
cleanup() {
    echo "--- Cleaning up services ---"
    docker compose -f docker-compose.test.yml down --volumes --remove-orphans
}
trap cleanup EXIT

echo "--- Starting services for refactor-layered-architecture ---"
docker compose -f docker-compose.test.yml up -d

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 15

echo "--- Installing server dependencies ---"
(cd src/server && npm ci)

echo "--- Running verification for refactor-layered-architecture ---"

# Set a unique database for this test run
export MONGO_URI_TEST="mongodb://localhost:27017/refactor-layered-architecture-$RANDOM"

# Run the specific test file for this task
npx jest --runInBand "tasks/refactor-layered-architecture/tests/architecture.test.ts"

echo "✅ refactor-layered-architecture verified"
