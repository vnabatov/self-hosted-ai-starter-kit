#!/bin/bash

echo "n8n Troubleshooting and Fix Script"
echo "================================="
echo

# Check if n8n is running
echo "Checking n8n status..."
if ! podman ps | grep -q n8n; then
  echo "n8n is not running! Starting it..."
  podman start n8n
  sleep 10
fi

# Import credentials directly
echo "Fixing n8n credentials..."
podman exec n8n sh -c "mkdir -p /home/node/.n8n/credentials"
podman exec n8n sh -c "cp /backup/credentials/*.json /home/node/.n8n/credentials/ 2>/dev/null"

# Update credential encryption
echo "Updating credential encryption with current key..."
podman exec -e N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY:-super-secret-key} n8n sh -c "node /usr/local/lib/node_modules/n8n/bin/n8n update:ownership"

# Restart n8n to apply changes
echo "Restarting n8n..."
podman restart n8n

echo
echo "Wait 20 seconds for n8n to restart..."
sleep 20

# Test if n8n is accessible
if curl -s http://localhost:5678/healthz > /dev/null 2>&1; then
  echo "✅ Success! n8n is now accessible at http://localhost:5678"
else
  echo "❌ n8n is still not accessible. Try these steps:"
  echo "1. Check the logs: podman logs n8n"
  echo "2. Verify the PostgreSQL container is running and accessible"
  echo "3. Verify your .env file has correct credentials"
  echo "4. Try a complete reset: ./reset-all.sh"
fi
