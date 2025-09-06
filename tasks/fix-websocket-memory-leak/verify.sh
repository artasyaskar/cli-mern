#!/usr/bin/env bash
set -euo pipefail

echo "--- Verifying task: fix-websocket-memory-leak ---"

# 1. Check for the event-bus.ts file
if [ ! -f "src/server/src/event-bus.ts" ]; then
    echo "Verification failed: event-bus.ts does not exist."
    exit 1
fi
echo "✔️ event-bus.ts exists."

# 2. Check websockets.ts for the fix
# The fix is to call eventBus.off() in the 'close' event handler.
# We can check if the 'close' handler contains the 'off' call.
if ! sed -n "/ws.on('close'/,/})/p" src/server/src/websockets.ts | grep -q "eventBus.off('some-event', handleSomeEvent);"; then
    echo "Verification failed: The 'close' handler in websockets.ts does not appear to remove the event listener."
    exit 1
fi
echo "✔️ WebSocket 'close' handler removes the event listener."

# 3. Check that the buggy code is not present (i.e., the close handler is not empty)
if grep -q "ws.on('close', () => {" src/server/src/websockets.ts && \
   !grep -q "eventBus.off" src/server/src/websockets.ts; then
    echo "Verification failed: The 'close' handler seems to be missing the fix."
    exit 1
fi
echo "✔️ The 'close' handler is not empty."


echo "--- Task fix-websocket-memory-leak verified successfully! ---"
