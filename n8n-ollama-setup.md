# Connecting N8N to Ollama

If you're experiencing connection issues between N8N and Ollama, follow these steps:

## From N8N UI

1. Open N8N at http://localhost:5678
2. Create a workflow
3. Add an "Ollama" node
4. Configure the Ollama node with these settings:
   - API Endpoint: `http://ollama:11434/api`
   - Model: `llama2` (or whichever model you've pulled)

## For Custom API Calls

If you're using HTTP Request nodes to call Ollama directly:

1. Use the URL: `http://ollama:11434/api/...`
2. Example for chat completion:
   ```
   POST http://ollama:11434/api/chat
   ```

## Troubleshooting

If you still experience `ECONNREFUSED` errors, try:

1. Running the diagnostic script to verify all services are running
   ```
   ./diagnose.sh
   ```

2. Check if Ollama is accessible within the n8n container:
   ```
   podman exec -it n8n curl http://ollama:11434/api/version
   ```

3. Restart the n8n container:
   ```
   podman restart n8n
   ```
