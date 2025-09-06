#!/usr/bin/env bash
set -euo pipefail

echo "--- Verifying task: add-jwt-authentication ---"

# This script checks that the solution for 'add-jwt-authentication' was applied correctly.

# 1. Check for dependencies in server's package.json
if ! grep -q '"jsonwebtoken":' "src/server/package.json"; then
    echo "Verification failed: 'jsonwebtoken' dependency not found."
    exit 1
fi
if ! grep -q '"bcryptjs":' "src/server/package.json"; then
    echo "Verification failed: 'bcryptjs' dependency not found."
    exit 1
fi
echo "✔️ JWT dependencies exist."

# 2. Check for new files
if [ ! -f "src/server/src/models/User.ts" ]; then
    echo "Verification failed: models/User.ts does not exist."
    exit 1
fi
if [ ! -f "src/server/src/middleware/auth.ts" ]; then
    echo "Verification failed: middleware/auth.ts does not exist."
    exit 1
fi
if [ ! -f "src/server/src/routes/authRoutes.ts" ]; then
    echo "Verification failed: routes/authRoutes.ts does not exist."
    exit 1
fi
if [ ! -f "src/server/src/controllers/authController.ts" ]; then
    echo "Verification failed: controllers/authController.ts does not exist."
    exit 1
fi
echo "✔️ New backend files for auth created."

# 3. Check for auth routes in server index.ts
if ! grep -q "app.use('/api/auth', authRoutes);" "src/server/src/index.ts"; then
    echo "Verification failed: Auth routes not registered in index.ts."
    exit 1
fi
echo "✔️ Auth routes registered."

# 4. Check for protected route in productRoutes.ts
if ! grep -q ".post(protect, createProduct)" "src/server/src/routes/productRoutes.ts"; then
    echo "Verification failed: Product creation route is not protected."
    exit 1
fi
echo "✔️ Product creation route is protected."

# 5. Check frontend App.tsx for auth UI
if ! grep -q 'const AuthForm =' "src/client/src/App.tsx"; then
    echo "Verification failed: AuthForm component not found in App.tsx."
    exit 1
fi
if ! grep -q 'const handleLogout =' "src/client/src/App.tsx"; then
    echo "Verification failed: Logout handler not found in App.tsx."
    exit 1
fi
echo "✔️ Frontend App.tsx has been updated for authentication."

echo "--- Task add-jwt-authentication verified successfully! ---"
