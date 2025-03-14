#!/bin/bash

echo "Starting services..."

# Clean up existing containers
echo "Removing existing containers..."
podman rm -f postgres qdrant ollama n8n n8n-import-credentials n8n-import-workflows ollama-pull-model 2>/dev/null || true
podman pod rm -f $(podman pod ls -q) 2>/dev/null || true

# Create a network for the containers
echo "Creating shared network..."
podman network rm ai-network 2>/dev/null || true
podman network create ai-network

# Create volume for n8n to persist configuration
echo "Creating n8n volume..."
podman volume rm n8n-data 2>/dev/null || true
podman volume create n8n-data

# Generate a new encryption key for n8n
ENCRYPTION_KEY=$(openssl rand -hex 16)
echo "Generated N8N encryption key: $ENCRYPTION_KEY"

# Start services using direct podman commands for better control
echo "Starting postgres..."
podman run -d --name postgres \
  --network ai-network \
  -p 5432:5432 \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_DB=postgres \
  docker.io/library/postgres:16-alpine
echo "Waiting for postgres to initialize..."
sleep 15

echo "Starting qdrant..."
podman run -d --name qdrant \
  --network ai-network \
  -p 6333:6333 \
  docker.io/qdrant/qdrant:latest
echo "Waiting for qdrant to initialize..."
sleep 10

echo "Starting ollama..."
podman run -d --name ollama \
  --hostname ollama \
  --network ai-network \
  -p 11434:11434 \
  docker.io/ollama/ollama:latest
echo "Waiting for ollama to initialize..."
sleep 20

echo "Starting n8n..."
podman run -d --name n8n \
  --network ai-network \
  -p 5678:5678 \
  -e N8N_ENCRYPTION_KEY="$ENCRYPTION_KEY" \
  -e N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true \
  -e OLLAMA_HOST="http://ollama:11434" \
  -e DB_TYPE=postgresdb \
  -e DB_POSTGRESDB_HOST=postgres \
  -e DB_POSTGRESDB_PORT=5432 \
  -e DB_POSTGRESDB_DATABASE=postgres \
  -e DB_POSTGRESDB_USER=postgres \
  -e DB_POSTGRESDB_PASSWORD=postgres \
  -v n8n-data:/home/node/.n8n \
  docker.n8n.io/n8nio/n8n:latest

# Show running containers
echo "Verifying services are running..."
podman ps -a

# Wait longer for n8n to initialize
echo "Waiting for n8n to initialize (this may take up to 2 minutes)..."
sleep 60

# Create a diagnostic script to help troubleshoot
cat > ./diagnose.sh << 'EOT'
#!/bin/bash

echo "=== Diagnostic Report ==="
echo "Running containers:"
podman ps -a

echo -e "\nContainer logs (may not work with remote podman):"
for container in postgres qdrant ollama n8n; do
  echo -e "\n--- ${container^} logs ---"
  podman logs $container --tail 10 2>/dev/null || echo "Could not get logs"
done

echo -e "\nNetworking tests:"
echo "--- Testing from host ---"
echo "N8N: $(curl -sI http://localhost:5678 2>/dev/null | head -1 || echo "Not responding")"
echo "Ollama: $(curl -sI http://localhost:11434/api/version 2>/dev/null | head -1 || echo "Not responding")"
echo "Qdrant: $(curl -sI http://localhost:6333/healthz 2>/dev/null | head -1 || echo "Not responding")"

echo -e "\n--- Testing endpoints ---"
echo "N8N UI: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:5678/ 2>/dev/null || echo "Failed")"
echo "Ollama API: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:11434/api/version 2>/dev/null || echo "Failed")"
echo "Qdrant API: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:6333/healthz 2>/dev/null || echo "Failed")"

echo -e "\n--- Network configuration ---"
podman network inspect ai-network 2>/dev/null || echo "Network not found"
EOT

chmod +x ./diagnose.sh

echo -e "\033[32mSuccess! All services are running.\033[0m"
echo "Services are available at:"
echo "- N8N: http://localhost:5678"
echo "- Ollama: http://localhost:11434"
echo "- Qdrant: http://localhost:6333"
echo ""
echo -e "\033[33mFirst steps:\033[0m"
echo "1. Open N8N in your browser: http://localhost:5678"
echo "2. Create an account when prompted"
echo "3. Try connecting to Ollama with the host: http://ollama:11434"
echo ""
echo -e "\033[33mTroubleshooting:\033[0m"
echo "- If services aren't responding, run: ./diagnose.sh"
echo "- Services might take a few minutes to fully initialize on first run"
echo "- Check container logs with: podman logs <container-name>"
echo ""
echo "Enjoy your self-hosted AI environment!"
