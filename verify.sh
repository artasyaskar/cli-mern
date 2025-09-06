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

# Get the absolute path of the script's directory
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# Determine which docker-compose file to use
DOCKER_COMPOSE_FILE="$SCRIPT_DIR/docker-compose.test.yml" # Default to the test-specific one
if [ "$TASK_ID" == "fix-mongo-transaction-rollback" ]; then
    DOCKER_COMPOSE_FILE="$SCRIPT_DIR/tasks/fix-mongo-transaction-rollback/docker-compose.replicaset.yml"
    echo "Using replica set docker-compose file."
fi

# Start services in the background
echo "Starting services with docker-compose..."
docker compose -f "$DOCKER_COMPOSE_FILE" up -d

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 15 # Wait for mongo to start
echo "Services started."

# Install server dependencies
echo "Installing server dependencies..."
(cd src/server && npm ci)

# Install root dependencies for Jest
echo "Installing root dependencies..."
npm install

echo "--- Setup complete ---"

# --- Task-specific verification ---
echo "--- Running task-specific verification for $TASK_ID ---"

# Set a unique database for this test run
export MONGO_URI_TEST="mongodb://localhost:27017/${TASK_ID}-${RANDOM}"
if [ "$TASK_ID" == "fix-mongo-transaction-rollback" ]; then
    # The replica set needs a different URI
    export MONGO_URI_TEST="mongodb://localhost:27017/test-db-replicaset-${RANDOM}?replicaSet=rs0"
fi

# Most tests run from the root directory to use the correct Jest config
cd "$SCRIPT_DIR"

# --- Task to Test File Mapping ---
declare -A task_test_map=(
    ["add-file-upload-s3"]="tasks/add-file-upload-s3/tests/upload.test.ts"
    ["add-full-text-search"]="tasks/add-full-text-search/tests/search.test.ts"
    ["add-jwt-authentication"]="tasks/add-jwt-authentication/tests/auth.test.ts tasks/add-jwt-authentication/tests/products.auth.test.ts"
    ["add-mock-payment-integration"]="tasks/add-mock-payment-integration/tests/payment.test.ts"
    ["add-role-based-access-control"]="tasks/add-role-based-access-control/tests/rbac.test.ts"
    ["add-security-enhancements"]="tasks/add-security-enhancements/tests/security.test.ts"
    ["add-websocket-notifications"]="tasks/add-websocket-notifications/tests/websocket.test.ts"
    ["fix-jwt-race-condition"]="tasks/fix-jwt-race-condition/tests/race.condition.test.ts"
    ["fix-mongo-transaction-rollback"]="tasks/fix-mongo-transaction-rollback/tests/transaction.test.ts"
    ["fix-websocket-memory-leak"]="tasks/fix-websocket-memory-leak/tests/memory.leak.test.ts"
    ["optimize-mongo-queries"]="tasks/optimize-mongo-queries/tests/aggregation.test.ts"
    ["refactor-layered-architecture"]="tasks/refactor-layered-architecture/tests/architecture.test.ts"
    ["refactor-react-components"]="tasks/refactor-react-components/tests/component.structure.test.ts"
)

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

    *)
        if [[ -n "${task_test_map[$TASK_ID]:-}" ]]; then
            test_files=${task_test_map[$TASK_ID]}
            echo "Running Jest tests for $TASK_ID: $test_files"
            npx jest --runInBand $test_files
        else
            echo "Error: No verification logic found for task '$TASK_ID'."
            exit 1
        fi
        ;;
esac

# Go back to the root directory
cd ../..

echo "--- Task-specific verification complete ---"
echo ""
echo "✅ --- Task $TASK_ID verified successfully! ---"
