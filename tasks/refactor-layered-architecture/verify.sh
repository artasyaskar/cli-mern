#!/usr/bin/env bash
set -euo pipefail

echo "--- Verifying task: refactor-layered-architecture ---"

# 1. Check for new directories
if [ ! -d "src/server/src/services" ]; then
    echo "Verification failed: 'services' directory does not exist."
    exit 1
fi
if [ ! -d "src/server/src/repositories" ]; then
    echo "Verification failed: 'repositories' directory does not exist."
    exit 1
fi
echo "✔️ New directories for services and repositories exist."

# 2. Check for new service and repository files
if [ ! -f "src/server/src/services/authService.ts" ]; then
    echo "Verification failed: services/authService.ts does not exist."
    exit 1
fi
if [ ! -f "src/server/src/services/productService.ts" ]; then
    echo "Verification failed: services/productService.ts does not exist."
    exit 1
fi
if [ ! -f "src/server/src/repositories/productRepository.ts" ]; then
    echo "Verification failed: repositories/productRepository.ts does not exist."
    exit 1
fi
echo "✔️ New service and repository files exist."

# 3. Check that controllers are importing from services
if ! grep -q "import authService from '../services/authService';" "src/server/src/controllers/authController.ts"; then
    echo "Verification failed: authController does not import from authService."
    exit 1
fi
if ! grep -q "import productService from '../services/productService';" "src/server/src/controllers/productController.ts"; then
    echo "Verification failed: productController does not import from productService."
    exit 1
fi
echo "✔️ Controllers import from the service layer."

# 4. Check that productService imports from productRepository
if ! grep -q "import productRepository from '../repositories/productRepository';" "src/server/src/services/productService.ts"; then
    echo "Verification failed: productService does not import from productRepository."
    exit 1
fi
echo "✔️ Product service imports from the repository layer."


echo "--- Task refactor-layered-architecture verified successfully! ---"
