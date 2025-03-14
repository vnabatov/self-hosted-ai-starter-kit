#!/bin/bash
set -e

echo "Starting All Services..."

# Clean up any existing containers
echo "Removing existing containers..."
podman rm -f postgres qdrant ollama n8n 2>/dev/null || true
podman pod rm -f $(podman pod ls -q) 2>/dev/null || true

# Load environment variables
source .env 2>/dev/null || true

# First create all containers but don't start them
echo "Creating containers (without starting)..."
podman-compose create

# Start containers one by one
echo "Starting PostgreSQL..."
podman start postgres

# Wait for PostgreSQL to be healthy
echo "Waiting for PostgreSQL to be ready..."
count=0
max_attempts=30
while [ $count -lt $max_attempts ]; do
  if podman exec postgres pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB} >/dev/null 2>&1; then
    echo "PostgreSQL is ready!"
    break
  fi
  echo "Waiting for PostgreSQL to start... ($((count+1))/$max_attempts)"
  sleep 3
  count=$((count+1))
done

if [ $count -eq $max_attempts ]; then
  echo "ERROR: PostgreSQL failed to start properly. Check the logs with: podman logs postgres"
  exit 1
fi

# Start Qdrant
echo "Starting Qdrant..."
podman start qdrant
sleep 5

# Start Ollama
echo "Starting Ollama..."
podman start ollama
sleep 10

# Start n8n
echo "Starting n8n..."
podman start n8n

# Wait for n8n to be healthy
echo "Waiting for n8n to be ready..."
count=0
max_attempts=40
while [ $count -lt $max_attempts ]; do
  if curl -s http://localhost:5678/healthz > /dev/null 2>&1; then
    echo "n8n is now available!"
    break
  fi
  echo "Waiting for n8n to start... ($((count+1))/$max_attempts)"
  sleep 5
  count=$((count+1))
done

if [ $count -eq $max_attempts ]; then
  echo "WARNING: n8n may not have started properly."
  echo "Try fixing credentials manually: ./fix-credentials.sh"
  echo "Check logs: podman logs n8n"
fi

# Pull Ollama model
echo "Pulling Ollama model (${MODEL:-gemma})..."
podman exec -e MODEL=${MODEL:-gemma} ollama sh -c "ollama pull \${MODEL:-gemma}" || echo "Model pull failed. The model may already be pulled or Ollama is not ready."

# Import n8n credentials directly
echo "Importing n8n credentials..."
podman exec n8n sh -c "mkdir -p /home/node/.n8n/credentials"
podman exec n8n sh -c "cp /backup/credentials/*.json /home/node/.n8n/credentials/ 2>/dev/null" || echo "No credentials to import or credentials directory not found."

# Import n8n workflows
echo "Importing n8n workflows..."
podman exec n8n n8n import:workflow --separate --input=/backup/workflows || echo "Failed to import workflows. Check if backup directory exists."

echo "Setup complete! All services are running."
echo "Access N8N at http://localhost:5678"
echo "Access Ollama at http://localhost:11434"
echo "Access Qdrant at http://localhost:6333"

echo "To check service status: ./troubleshoot.sh"
echo "To see service logs: podman logs -f <container-name>"
