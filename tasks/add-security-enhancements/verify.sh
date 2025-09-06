#!/usr/bin/env bash
set -euo pipefail

echo "--- Verifying task: add-security-enhancements ---"

# 1. Check for dependencies in server's package.json
if ! grep -q '"helmet":' "src/server/package.json"; then
    echo "Verification failed: 'helmet' dependency not found."
    exit 1
fi
if ! grep -q '"express-rate-limit":' "src/server/package.json"; then
    echo "Verification failed: 'express-rate-limit' dependency not found."
    exit 1
fi
if ! grep -q '"express-validator":' "src/server/package.json"; then
    echo "Verification failed: 'express-validator' dependency not found."
    exit 1
fi
echo "✔️ Security dependencies exist."

# 2. Check for Helmet usage in index.ts
if ! grep -q "app.use(helmet());" "src/server/src/index.ts"; then
    echo "Verification failed: Helmet is not used in index.ts."
    exit 1
fi
echo "✔️ Helmet is used."

# 3. Check for rate limiting on login route
if ! grep -q "router.post('/login', loginLimiter, loginUser);" "src/server/src/routes/authRoutes.ts"; then
    echo "Verification failed: Login route is not rate-limited."
    exit 1
fi
echo "✔️ Login route is rate-limited."

# 4. Check for validation middleware file
if [ ! -f "src/server/src/middleware/validation.ts" ]; then
    echo "Verification failed: middleware/validation.ts does not exist."
    exit 1
fi
echo "✔️ Validation middleware exists."

# 5. Check for validation on registration route
if ! grep -q "router.post('/register', validateRegistration, registerUser);" "src/server/src/routes/authRoutes.ts"; then
    echo "Verification failed: Registration route is not validated."
    exit 1
fi
echo "✔️ Registration route is validated."

# 6. Check for validation on product creation route
if ! grep -q ".post(validateProductCreation, protect, admin, createProduct);" "src/server/src/routes/productRoutes.ts"; then
    echo "Verification failed: Product creation route is not validated."
    exit 1
fi
echo "✔️ Product creation route is validated."

echo "--- Task add-security-enhancements verified successfully! ---"
