#!/usr/bin/env bash
set -euo pipefail

echo "--- Verifying task: devops-docker-healthcheck ---"

# 1. Check for the wait script
if [ ! -f "scripts/wait-for-services.sh" ]; then
    echo "Verification failed: scripts/wait-for-services.sh does not exist."
    exit 1
fi
if [ ! -x "scripts/wait-for-services.sh" ]; then
    echo "Verification failed: scripts/wait-for-services.sh is not executable."
    exit 1
fi
echo "✔️ Wait script exists and is executable."

# 2. Check docker-compose.yml for the new redis service
# A simple grep is sufficient to check for the service definition.
if ! grep -q "redis:" "docker-compose.yml"; then
    echo "Verification failed: 'redis' service not found in docker-compose.yml."
    exit 1
fi
echo "✔️ 'redis' service exists."

# 3. Check for healthchecks
# We can check for the 'healthcheck:' key under the service definitions.
# This is not a perfect YAML parser, but it's a good heuristic.
if ! sed -n '/^  mongo:/,/^  [^ ]/p' docker-compose.yml | grep -q 'healthcheck:'; then
    echo "Verification failed: 'mongo' service does not have a healthcheck."
    exit 1
fi
if ! sed -n '/^  redis:/,/^  [^ ]/p' docker-compose.yml | grep -q 'healthcheck:'; then
    echo "Verification failed: 'redis' service does not have a healthcheck."
    exit 1
fi
echo "✔️ Healthchecks for mongo and redis exist."

# 4. Check that the api service uses the wait script
if ! grep -q 'command: sh -c "/app/scripts/wait-for-services.sh mongo:27017 redis:6379 && npm run dev"' docker-compose.yml; then
    echo "Verification failed: API service does not use the wait script in its command."
    exit 1
fi
echo "✔️ API service uses the wait script."

# 5. Check that the api service depends on mongo and redis with healthcheck condition
if ! sed -n '/^  api:/,/^  [^ ]/p' docker-compose.yml | grep -q 'condition: service_healthy'; then
    echo "Verification failed: API service does not depend on a healthy service."
    exit 1
fi
echo "✔️ API service depends on healthy services."


echo "--- Task devops-docker-healthcheck verified successfully! ---"
