#!/usr/bin/env bash
set -euo pipefail

echo "--- Verifying task: fix-jwt-race-condition ---"

# This script checks that the solution for 'fix-jwt-race-condition' was applied correctly.
# It checks that the 'introduce_bug.sh' was NOT applied, and that the 'solution.sh' WAS.

# 1. Check User model for 'isActive' field. This should be present in both bug and solution.
if ! grep -q "isActive: boolean;" "src/server/src/models/User.ts"; then
    echo "Verification failed: 'isActive' field not found in User model."
    exit 1
fi
echo "✔️ User model has 'isActive' field."

# 2. Check for logout/me routes and controller functions.
if ! grep -q "router.post('/logout', protect, logoutUser);" "src/server/src/routes/authRoutes.ts"; then
    echo "Verification failed: Logout route not found."
    exit 1
fi
if ! grep -q "export const logoutUser = async" "src/server/src/controllers/authController.ts"; then
    echo "Verification failed: 'logoutUser' function not found in authController."
    exit 1
fi
echo "✔️ Logout functionality exists."

# 3. Check the middleware for the fix.
# The fix involves re-checking the user's status after the async gap.
# A simple way to check this is to look for the second `User.findById` call.
# Count the occurrences of 'User.findById'. The fixed file should have 2.
# The buggy file has only 1.
count=$(grep -c "User.findById(decoded.id)" "src/server/src/middleware/auth.ts")
if [ "$count" -ne 2 ]; then
    echo "Verification failed: The auth middleware does not appear to have the race condition fix."
    echo "Expected to find 2 calls to User.findById, but found $count."
    exit 1
fi
echo "✔️ Auth middleware appears to contain the race condition fix."

# 4. Check that the buggy code is not present.
# The buggy code calls next() without a final check.
if grep -q "await simulateAsyncOperation();\s*next();" "src/server/src/middleware/auth.ts"; then
    echo "Verification failed: The middleware seems to contain the buggy code (calling next() right after the async operation)."
    exit 1
fi
echo "✔️ Buggy logic is not present in the middleware."


echo "--- Task fix-jwt-race-condition verified successfully! ---"
