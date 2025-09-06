#!/usr/bin/env bash
set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "Error: Please provide a TASK_ID as the first argument."
  echo "Usage: ./verify.sh <task-id>"
  exit 1
fi
TASK_ID=$1

echo "--- Verifying task: $TASK_ID ---"

# --- Pre-flight checks and setup ---
echo "--- Starting services and installing dependencies ---"

# Function to clean up background processes and services on script exit
cleanup() {
    echo "--- Cleaning up services ---"
    if [ -n "${DOCKER_COMPOSE_FILE:-}" ]; then
        docker compose -f "$DOCKER_COMPOSE_FILE" down --volumes --remove-orphans
    fi
    # Kill background jobs
    if (jobs -p | grep .); then
       kill $(jobs -p)
    fi
}
trap cleanup EXIT

# Determine which docker-compose file to use
DOCKER_COMPOSE_FILE="docker-compose.test.yml" # Default to the test-specific one
if [ "$TASK_ID" == "fix-mongo-transaction-rollback" ]; then
    DOCKER_COMPOSE_FILE="tasks/fix-mongo-transaction-rollback/docker-compose.replicaset.yml"
    echo "Using replica set docker-compose file."
fi

# Start services in the background
echo "Starting services with docker-compose..."
docker compose -f "$DOCKER_COMPOSE_FILE" up -d

# Wait for services to be ready
echo "Waiting for services to be healthy..."
WAIT_LIMIT=24 # 24*5s = 120s timeout
WAIT_COUNT=0
# Loop until all containers with a health check are healthy.
while true; do
    UNHEALTHY_COUNT=$(docker compose -f "$DOCKER_COMPOSE_FILE" ps -a --format '{{.Service}} {{.Health}}' | grep -v "(healthy)" | grep -c "(unhealthy)")

    if [ "$UNHEALTHY_COUNT" -eq 0 ]; then
        HEALTHY_COUNT=$(docker compose -f "$DOCKER_COMPOSE_FILE" ps -a --format '{{.Service}} {{.Health}}' | grep -c "(healthy)")
        if [ "$HEALTHY_COUNT" -gt 0 ]; then
            echo "All services are healthy."
            break
        fi
    fi

    if [ $WAIT_COUNT -ge $WAIT_LIMIT ]; then
        echo "Timeout: Docker containers did not become healthy in 120 seconds."
        docker compose -f "$DOCKER_COMPOSE_FILE" logs
        exit 1
    fi

    echo "Containers not healthy yet (Unhealthy: $UNHEALTHY_COUNT). Waiting 5s..."
    sleep 5
    WAIT_COUNT=$((WAIT_COUNT+1))
done

# Install server dependencies
echo "Installing server dependencies..."
(cd src/server && npm ci)

echo "--- Setup complete ---"

# --- Task-specific verification ---
echo "--- Running task-specific verification for $TASK_ID ---"

# Set a unique database for this test run
export MONGO_URI_TEST="mongodb://localhost:27017/${TASK_ID}-${RANDOM}"
if [ "$TASK_ID" == "fix-mongo-transaction-rollback" ]; then
    # The replica set needs a different URI
    export MONGO_URI_TEST="mongodb://localhost:27017/test-db-replicaset-${RANDOM}?replicaSet=rs0"
fi

# Most tests run from the server directory
cd src/server

case "$TASK_ID" in
    add-e2e-tests-cypress)
        echo "Starting server for E2E tests..."
        (npm run dev > ../../server-dev.log 2>&1 &)
        echo "Waiting for server to be ready on port 5001..."
        npx wait-on http://localhost:5001 --timeout 120000

        echo "Installing client dependencies for E2E tests..."
        (cd ../client && npm ci)
        echo "Starting client dev server for E2E tests..."
        (cd ../client && npm run dev > ../../client-dev-server.log 2>&1 &)

        echo "Waiting for client server to start on port 3000..."
        npx wait-on http://localhost:3000 --timeout 120000

        echo "Client server is up. Running Cypress tests..."
        (cd ../.. && npx cypress run)
        ;;

    devops-docker-healthcheck)
        # This task uses a shell script for verification.
        echo "Running docker healthcheck test..."
        bash "../../tasks/devops-docker-healthcheck/tests/docker.setup.test.sh"
        ;;

    add-jwt-authentication|add-mock-payment-integration|add-role-based-access-control|add-security-enhancements|add-websocket-notifications|fix-jwt-race-condition|refactor-layered-architecture|refactor-react-components|add-file-upload-s3|fix-websocket-memory-leak|add-full-text-search|optimize-mongo-queries|fix-mongo-transaction-rollback)
        # These tasks all use Jest test files.
        # Running Jest with a path to the task's test directory will run all tests within it.
        TEST_PATH_PATTERN="../../tasks/${TASK_ID}/tests"
        echo "Running Jest tests in ${TEST_PATH_PATTERN}..."
        npx jest --runInBand --testPathPattern "$TEST_PATH_PATTERN"
        ;;

    *)
        echo "Error: No verification logic found for task '$TASK_ID'."
        exit 1
        ;;
esac

# Go back to the root directory
cd ../..

echo "--- Task-specific verification complete ---"
echo ""
echo "✅ --- Task $TASK_ID verified successfully! ---"
