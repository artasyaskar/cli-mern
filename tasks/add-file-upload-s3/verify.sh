#!/usr/bin/env bash
set -euo pipefail

echo "--- Verifying task: add-file-upload-s3 ---"

# This script checks that the solution for 'add-file-upload-s3' was applied correctly.

# 1. Check for multer dependency in server's package.json
if ! grep -q '"multer":' "src/server/package.json"; then
    echo "Verification failed: 'multer' dependency not found in src/server/package.json."
    exit 1
fi
echo "✔️ multer dependency exists."

# 2. Check for the 'uploads' directory
if [ ! -d "uploads" ]; then
    echo "Verification failed: 'uploads' directory does not exist at the project root."
    exit 1
fi
echo "✔️ 'uploads' directory exists."

# 3. Check for the upload middleware file
if [ ! -f "src/server/src/middleware/upload.ts" ]; then
    echo "Verification failed: middleware/upload.ts does not exist."
    exit 1
fi
echo "✔️ upload.ts middleware exists."

# 4. Check Product model for 'imageUrl'
if ! grep -q 'imageUrl?: string;' "src/server/src/models/Product.ts"; then
    echo "Verification failed: 'imageUrl' not found in Product interface in Product.ts."
    exit 1
fi
if ! grep -q 'imageUrl: { type: String }' "src/server/src/models/Product.ts"; then
    echo "Verification failed: 'imageUrl' not found in Product schema in Product.ts."
    exit 1
fi
echo "✔️ Product model updated with imageUrl."

# 5. Check controller for 'uploadProductImage' function
if ! grep -q 'export const uploadProductImage' "src/server/src/controllers/productController.ts"; then
    echo "Verification failed: 'uploadProductImage' function not found in productController.ts."
    exit 1
fi
echo "✔️ productController.ts has the upload function."

# 6. Check routes for the new image upload endpoint
if ! grep -q "router.route('/:id/image').post" "src/server/src/routes/productRoutes.ts"; then
    echo "Verification failed: Image upload route not found in productRoutes.ts."
    exit 1
fi
echo "✔️ Image upload route exists."

# 7. Check server index.ts for static serving of 'uploads'
if ! grep -q "app.use('/uploads', express.static('uploads'));" "src/server/src/index.ts"; then
    echo "Verification failed: Server does not serve the /uploads directory statically."
    exit 1
fi
echo "✔️ Server serves /uploads directory."

# 8. Check frontend App.tsx for image rendering logic
if ! grep -q '{product.imageUrl && <img' "src/client/src/App.tsx"; then
    echo "Verification failed: Frontend does not appear to render the product image."
    exit 1
fi
echo "✔️ Frontend App.tsx appears to render the image."

echo "--- Task add-file-upload-s3 verified successfully! ---"
