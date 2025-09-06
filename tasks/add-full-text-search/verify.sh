#!/usr/bin/env bash
set -euo pipefail

echo "--- Verifying task: add-full-text-search ---"

# This script checks that the solution for 'add-full-text-search' was applied correctly.

# 1. Check for text index in Product model
if ! grep -q "ProductSchema.index({ name: 'text', description: 'text' });" "src/server/src/models/Product.ts"; then
    echo "Verification failed: Text index not found in Product.ts."
    exit 1
fi
echo "✔️ Product model has text index."

# 2. Check for search method in repository
if ! grep -q "async search(query: string)" "src/server/src/repositories/productRepository.ts"; then
    echo "Verification failed: 'search' method not found in productRepository.ts."
    exit 1
fi
echo "✔️ Product repository has search method."

# 3. Check for search method in service
if ! grep -q "async searchProducts(query: string)" "src/server/src/services/productService.ts"; then
    echo "Verification failed: 'searchProducts' method not found in productService.ts."
    exit 1
fi
echo "✔️ Product service has search method."

# 4. Check for search function in controller
if ! grep -q "export const searchProducts" "src/server/src/controllers/productController.ts"; then
    echo "Verification failed: 'searchProducts' function not found in productController.ts."
    exit 1
fi
echo "✔️ Product controller has search function."

# 5. Check for search route
if ! grep -q "router.route('/search').get(searchProducts);" "src/server/src/routes/productRoutes.ts"; then
    echo "Verification failed: Search route not found in productRoutes.ts."
    exit 1
fi
echo "✔️ Search route exists."

# 6. Check frontend App.tsx for search UI indicators
if ! grep -q "const useDebounce = " "src/client/src/App.tsx"; then
    echo "Verification failed: 'useDebounce' hook not found in App.tsx."
    exit 1
fi
if ! grep -q 'placeholder="Search for products' "src/client/src/App.tsx"; then
    echo "Verification failed: Search input not found in App.tsx."
    exit 1
fi
echo "✔️ Frontend App.tsx has been updated for search."

echo "--- Task add-full-text-search verified successfully! ---"
