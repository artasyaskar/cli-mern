#!/usr/bin/env bash
set -euo pipefail

echo "--- Verifying task: add-e2e-tests-cypress ---"

# This script checks that the solution for 'add-e2e-tests-cypress' was applied correctly.

# 1. Check if cypress.config.ts exists at the root
if [ ! -f "cypress.config.ts" ]; then
    echo "Verification failed: cypress.config.ts does not exist at the project root."
    exit 1
fi
echo "✔️ cypress.config.ts exists."

# 2. Check if the client package.json was updated
if ! grep -q '"cypress":' "src/client/package.json"; then
    echo "Verification failed: 'cypress' dependency not found in src/client/package.json."
    exit 1
fi
if ! grep -q '"e2e": "cypress open"' "src/client/package.json"; then
    echo "Verification failed: 'e2e' script not found in src/client/package.json."
    exit 1
fi
echo "✔️ client/package.json updated with cypress dependency and scripts."

# 3. Check if the Cypress test files were created
if [ ! -f "cypress/e2e/login.cy.ts" ]; then
    echo "Verification failed: cypress/e2e/login.cy.ts was not created."
    exit 1
fi
if [ ! -f "cypress/e2e/checkout.cy.ts" ]; then
    echo "Verification failed: cypress/e2e/checkout.cy.ts was not created."
    exit 1
fi
echo "✔️ Cypress test files exist."

# 4. Check that .gitkeep was NOT copied
if [ -f "cypress/e2e/.gitkeep" ]; then
    echo "Verification failed: .gitkeep file should not be present in cypress/e2e/."
    exit 1
fi
echo "✔️ .gitkeep file was not copied."

echo "--- Task add-e2e-tests-cypress verified successfully! ---"
