#!/usr/bin/env bash
set -euo pipefail

echo "--- Verifying task: refactor-react-components ---"

# 1. Check for the new components directory
if [ ! -d "src/client/src/components" ]; then
    echo "Verification failed: 'components' directory does not exist."
    exit 1
fi
echo "✔️ 'components' directory exists."

# 2. Check for the new component files
components=(
    "AuthForm.tsx"
    "ProductList.tsx"
    "AddProductForm.tsx"
    "SearchBar.tsx"
    "Notifications.tsx"
)
for component in "${components[@]}"; do
    if [ ! -f "src/client/src/components/$component" ]; then
        echo "Verification failed: Component file '$component' does not exist."
        exit 1
    fi
done
echo "✔️ All new component files exist."

# 3. Check that App.tsx imports the new components
if ! grep -q "import { AuthForm } from './components/AuthForm';" "src/client/src/App.tsx"; then
    echo "Verification failed: App.tsx does not import AuthForm."
    exit 1
fi
if ! grep -q "import { ProductList } from './components/ProductList';" "src/client/src/App.tsx"; then
    echo "Verification failed: App.tsx does not import ProductList."
    exit 1
fi
if ! grep -q "import { SearchBar } from './components/SearchBar';" "src/client/src/App.tsx"; then
    echo "Verification failed: App.tsx does not import SearchBar."
    exit 1
fi
echo "✔️ App.tsx imports the new components."


echo "--- Task refactor-react-components verified successfully! ---"
