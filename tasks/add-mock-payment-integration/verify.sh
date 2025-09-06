#!/usr/bin/env bash
set -euo pipefail

echo "--- Verifying task: add-mock-payment-integration ---"

# 1. Check for new backend files
if [ ! -f "src/server/src/controllers/checkoutController.ts" ]; then
    echo "Verification failed: controllers/checkoutController.ts does not exist."
    exit 1
fi
if [ ! -f "src/server/src/routes/checkoutRoutes.ts" ]; then
    echo "Verification failed: routes/checkoutRoutes.ts does not exist."
    exit 1
fi
echo "✔️ New backend files for checkout exist."

# 2. Check for checkout routes in server index.ts
if ! grep -q "app.use('/api/checkout', checkoutRoutes);" "src/server/src/index.ts"; then
    echo "Verification failed: Checkout routes not registered in index.ts."
    exit 1
fi
echo "✔️ Checkout routes registered."

# 3. Check for new frontend component files
if [ ! -f "src/client/src/components/CartView.tsx" ]; then
    echo "Verification failed: components/CartView.tsx does not exist."
    exit 1
fi
echo "✔️ CartView.tsx component exists."

# 4. Check for updated ProductList component
if ! grep -q "onAddToCart: (productId: string) => void;" "src/client/src/components/ProductList.tsx"; then
    echo "Verification failed: ProductList.tsx does not seem to have the onAddToCart prop."
    exit 1
fi
if ! grep -q "<button onClick={() => onAddToCart(product._id)}>Add to Cart</button>" "src/client/src/components/ProductList.tsx"; then
    echo "Verification failed: ProductList.tsx does not seem to have an 'Add to Cart' button."
    exit 1
fi
echo "✔️ ProductList.tsx has been updated."

# 5. Check for updated App.tsx
if ! grep -q "const [cart, setCart] = useState<Record<string, number>>({});" "src/client/src/App.tsx"; then
    echo "Verification failed: App.tsx does not seem to manage cart state."
    exit 1
fi
if ! grep -q "<CartView" "src/client/src/App.tsx"; then
    echo "Verification failed: App.tsx does not seem to render the CartView component."
    exit 1
fi
echo "✔️ App.tsx has been updated for cart functionality."


echo "--- Task add-mock-payment-integration verified successfully! ---"
