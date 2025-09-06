#!/usr/bin/env bash
set -euo pipefail

echo "--- Verifying task: optimize-mongo-queries ---"

# 1. Check for the Purchase model and routes
if [ ! -f "src/server/src/models/Purchase.ts" ]; then
    echo "Verification failed: models/Purchase.ts does not exist."
    exit 1
fi
if [ ! -f "src/server/src/routes/purchaseRoutes.ts" ]; then
    echo "Verification failed: routes/purchaseRoutes.ts does not exist."
    exit 1
fi
echo "✔️ Purchase model and routes exist."

# 2. Check productRepository.ts for the aggregation pipeline
if ! grep -q "Product.aggregate(\[" "src/server/src/repositories/productRepository.ts"; then
    echo "Verification failed: No aggregation pipeline found in productRepository.ts."
    exit 1
fi
echo "✔️ productRepository.ts uses an aggregation pipeline."

# 3. Check that the inefficient loop is NOT present
if grep -q "for (const product of products)" "src/server/src/repositories/productRepository.ts"; then
    echo "Verification failed: The inefficient 'for' loop seems to still be present in the repository."
    exit 1
fi
echo "✔️ Inefficient loop has been removed."


echo "--- Task optimize-mongo-queries verified successfully! ---"
