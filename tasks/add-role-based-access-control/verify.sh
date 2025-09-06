#!/usr/bin/env bash
set -euo pipefail

echo "--- Verifying task: add-role-based-access-control ---"

# 1. Check User model for 'role' field
if ! grep -q "role: string;" "src/server/src/models/User.ts"; then
    echo "Verification failed: 'role' field not found in User interface."
    exit 1
fi
if ! grep -q "role: {\
    type: String,\
    enum: \['user', 'admin'\],\
    default: 'user',\
  " "src/server/src/models/User.ts"; then
    echo "Verification failed: 'role' field not found in User schema."
    exit 1
fi
echo "✔️ User model has 'role' field."

# 2. Check auth middleware for 'admin' function and async 'protect'
if ! grep -q "export const admin = " "src/server/src/middleware/auth.ts"; then
    echo "Verification failed: 'admin' middleware function not found."
    exit 1
fi
if ! grep -q "export const protect = async" "src/server/src/middleware/auth.ts"; then
    echo "Verification failed: 'protect' middleware is not async."
    exit 1
fi
echo "✔️ Auth middleware is updated."

# 3. Check for new user controller and routes
if [ ! -f "src/server/src/controllers/userController.ts" ]; then
    echo "Verification failed: userController.ts does not exist."
    exit 1
fi
if [ ! -f "src/server/src/routes/userRoutes.ts" ]; then
    echo "Verification failed: userRoutes.ts does not exist."
    exit 1
fi
echo "✔️ User controller and routes exist."

# 4. Check for user routes in server index.ts
if ! grep -q "app.use('/api/users', userRoutes);" "src/server/src/index.ts"; then
    echo "Verification failed: User routes not registered in index.ts."
    exit 1
fi
echo "✔️ User routes registered."

# 5. Check for admin protection on product creation route
if ! grep -q ".post(protect, admin, createProduct)" "src/server/src/routes/productRoutes.ts"; then
    echo "Verification failed: Product creation route is not protected by admin middleware."
    exit 1
fi
echo "✔️ Product creation route is admin-protected."

# 6. Check seed script for admin user creation
if ! grep -q "role: 'admin'" "db/seed.js"; then
    echo "Verification failed: Seed script does not create an admin user."
    exit 1
fi
echo "✔️ Seed script creates an admin user."

echo "--- Task add-role-based-access-control verified successfully! ---"
