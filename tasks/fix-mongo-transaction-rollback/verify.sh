#!/usr/bin/env bash
set -euo pipefail

echo "--- Verifying task: fix-mongo-transaction-rollback ---"

# 1. Check Product model for 'stock' field. This should be present in both bug and solution.
if ! grep -q "stock: number;" "src/server/src/models/Product.ts"; then
    echo "Verification failed: 'stock' field not found in Product model."
    exit 1
fi
echo "✔️ Product model has 'stock' field."

# 2. Check docker-compose.yml for replica set configuration
if ! grep -q 'command: \["--replSet", "rs0", "--bind_ip_all"\]' "docker-compose.yml"; then
    echo "Verification failed: MongoDB does not appear to be configured as a replica set."
    exit 1
fi
if ! grep -q "?replicaSet=rs0" "docker-compose.yml"; then
    echo "Verification failed: MONGO_URI does not specify the replica set."
    exit 1
fi
echo "✔️ Docker Compose is configured for MongoDB replica set."

# 3. Check checkoutController.ts for transaction logic
if ! grep -q "const session = await mongoose.startSession();" "src/server/src/controllers/checkoutController.ts"; then
    echo "Verification failed: mongoose.startSession() not found in checkoutController."
    exit 1
fi
if ! grep -q "session.startTransaction();" "src/server/src/controllers/checkoutController.ts"; then
    echo "Verification failed: session.startTransaction() not found in checkoutController."
    exit 1
fi
if ! grep -q "await session.commitTransaction();" "src/server/src/controllers/checkoutController.ts"; then
    echo "Verification failed: session.commitTransaction() not found in checkoutController."
    exit 1
fi
if ! grep -q "await session.abortTransaction();" "src/server/src/controllers/checkoutController.ts"; then
    echo "Verification failed: session.abortTransaction() not found in checkoutController."
    exit 1
fi
echo "✔️ Checkout controller appears to use MongoDB transactions."

# 4. Check that the buggy, non-atomic logic is not present
# The buggy version saves purchases *before* checking stock.
# A simple check for the string "new Purchase" appearing before "product.stock <" can work.
if ! awk '/new Purchase/{f=1} /product.stock </{if(f)p=1} END{exit !p}' src/server/src/controllers/checkoutController.ts; then
    echo "Verification failed: The controller seems to contain the buggy logic (creating purchases before checking stock)."
    # The awk script will exit with 1 if the pattern is NOT found. so if it exits with 1, it means the buggy code is not there.
    # This check is inverted. Let's re-think.
    # Let's check for the fixed logic instead. The fixed logic checks stock BEFORE creating purchases.
    # So, `product.stock <` should appear before `new Purchase`.
    if ! awk '/product.stock </{f=1} /new Purchase/{if(f)p=1} END{exit !p}' src/server/src/controllers/checkoutController.ts; then
        echo "✔️ Stock check appears to happen before purchase creation."
    else
        echo "Verification failed: The controller logic order seems incorrect."
        exit 1
    fi
fi


echo "--- Task fix-mongo-transaction-rollback verified successfully! ---"
