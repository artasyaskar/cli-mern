#!/usr/bin/env bash
set -euo pipefail

echo "--- Verifying task: add-websocket-notifications ---"

# 1. Check for 'ws' dependency in server's package.json
if ! grep -q '"ws":' "src/server/package.json"; then
    echo "Verification failed: 'ws' dependency not found."
    exit 1
fi
echo "✔️ 'ws' dependency exists."

# 2. Check for websockets.ts module
if [ ! -f "src/server/src/websockets.ts" ]; then
    echo "Verification failed: websockets.ts module not found."
    exit 1
fi
echo "✔️ websockets.ts module exists."

# 3. Check index.ts for http server and websocket init
if ! grep -q "const httpServer = createServer(app);" "src/server/src/index.ts"; then
    echo "Verification failed: http.Server not created in index.ts."
    exit 1
fi
if ! grep -q "initWebSocketServer(httpServer);" "src/server/src/index.ts"; then
    echo "Verification failed: WebSocket server not initialized in index.ts."
    exit 1
fi
if ! grep -q "export default httpServer;" "src/server/src/index.ts"; then
    echo "Verification failed: index.ts does not export httpServer."
    exit 1
fi
echo "✔️ index.ts correctly configured for WebSockets."

# 4. Check productService.ts for broadcast call
if ! grep -q "broadcast({ type: \"NEW_PRODUCT\", payload: newProduct });" "src/server/src/services/productService.ts"; then
    echo "Verification failed: Product service does not broadcast new products."
    exit 1
fi
echo "✔️ Product service broadcasts new products."

# 5. Check for new frontend files
if [ ! -f "src/client/src/hooks/useProductWebSocket.ts" ]; then
    echo "Verification failed: hooks/useProductWebSocket.ts does not exist."
    exit 1
fi
if [ ! -f "src/client/src/components/Notifications.tsx" ]; then
    echo "Verification failed: components/Notifications.tsx does not exist."
    exit 1
fi
echo "✔️ New frontend files for notifications exist."

# 6. Check App.tsx for notification logic
if ! grep -q "const \[notifications, setNotifications] = useState<string\[]>([]);" "src/client/src/App.tsx"; then
    echo "Verification failed: App.tsx does not seem to manage notification state."
    exit 1
fi
if ! grep -q "<Notifications notifications={notifications} />" "src/client/src/App.tsx"; then
    echo "Verification failed: App.tsx does not seem to render the Notifications component."
    exit 1
fi
echo "✔️ App.tsx has been updated for notifications."

echo "--- Task add-websocket-notifications verified successfully! ---"
