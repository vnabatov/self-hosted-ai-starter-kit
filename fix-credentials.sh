#!/bin/bash

echo "This script will fix n8n credentials by directly copying them into the n8n storage volume."
echo "This is helpful if you're experiencing issues with credential imports."

# Check if n8n is running
if ! podman ps | grep -q n8n; then
  echo "Error: n8n container is not running. Please start it first."
  exit 1
fi

# Copy credentials directly into n8n volume
echo "Copying credentials to n8n storage..."
podman exec n8n sh -c "mkdir -p /home/node/.n8n/credentials"
podman exec n8n sh -c "cp /backup/credentials/*.json /home/node/.n8n/credentials/ 2>/dev/null"

# Restart n8n to apply changes
echo "Restarting n8n to apply changes..."
podman restart n8n

echo "Credentials have been copied. Please check n8n at http://localhost:5678"
echo "If issues persist, try resetting the encryption key with: ./reset-n8n.sh"
