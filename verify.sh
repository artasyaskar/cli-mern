#!/usr/bin/env bash
set -euo pipefail

if [ -z "${TASK_ID:-}" ]; then
  echo "Error: TASK_ID environment variable is not set."
  exit 1
fi

echo "--- Verifying task: $TASK_ID ---"

# --- Pre-flight checks and setup ---
echo "--- Starting services and installing dependencies ---"

# Function to clean up background processes and services on script exit
cleanup() {
    echo "--- Cleaning up services ---"
    if [ -n "${DOCKER_COMPOSE_FILE:-}" ]; then
        docker-compose -f "$DOCKER_COMPOSE_FILE" down --volumes --remove-orphans
    fi
}
trap cleanup EXIT

# Determine which docker-compose file to use
DOCKER_COMPOSE_FILE="docker-compose.yml"
if [ "$TASK_ID" == "fix-mongo-transaction-rollback" ]; then
    DOCKER_COMPOSE_FILE="tasks/fix-mongo-transaction-rollback/docker-compose.replicaset.yml"
    echo "Using replica set docker-compose file."
fi

# Start services in the background
echo "Starting services with docker-compose..."
docker-compose -f "$DOCKER_COMPOSE_FILE" up -d

# Wait for services to be ready
echo "Waiting for services to be ready..."
# A more robust solution would check health status, but a sleep is sufficient for this context.
sleep 15

# Install server dependencies
echo "Installing server dependencies..."
(cd src/server && npm ci)

echo "--- Setup complete ---"

# --- Task-specific verification ---
echo "--- Running task-specific verification for $TASK_ID ---"

# Set a unique database for this test run
export MONGO_URI_TEST="mongodb://mongo:27017/${TASK_ID}-${RANDOM}"
if [ "$TASK_ID" == "fix-mongo-transaction-rollback" ]; then
    # The replica set needs a different URI and cannot use the random DB name approach
    export MONGO_URI_TEST="mongodb://localhost:27017/test-db-replicaset-${RANDOM}?replicaSet=rs0"
fi

# Most tests run from the server directory
cd src/server

case "$TASK_ID" in
    add-file-upload-s3)
        npx jest --runInBand --testPathPattern "../../tasks/add-file-upload-s3/tests/upload.test.ts"
        ;;
    add-e2e-tests-cypress)
        echo "Installing client dependencies for E2E tests..."
        (cd ../client && npm ci)
        echo "Starting client dev server for E2E tests..."
        (cd ../client && npm run dev > ../../client-dev-server.log 2>&1 &)

        echo "Waiting for client server to start on port 3000..."
        npx wait-on http://localhost:3000 --timeout 120000

        echo "Client server is up. Running Cypress tests..."
        # Cypress tests from the root where cypress.config.ts is.
        # The `cd ../..` is because we are in `src/server`.
        (cd ../.. && npx cypress run)
        ;;
    fix-websocket-memory-leak)
        npx jest --runInBand --testPathPattern "../../tasks/fix-websocket-memory-leak/tests/memory.leak.test.ts"
        ;;
    add-full-text-search)
        npx jest --runInBand --testPathPattern "../../tasks/add-full-text-search/tests/search.test.ts"
        ;;
    optimize-mongo-queries)
        npx jest --runInBand --testPathPattern "../../tasks/optimize-mongo-queries/tests/aggregation.test.ts"
        ;;
    fix-mongo-transaction-rollback)
        npx jest --runInBand --testPathPattern "../../tasks/fix-mongo-transaction-rollback/tests/transaction.test.ts"
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
