# Self-Hosted AI Starter Kit

This project provides a self-hosted environment with:
- Ollama (LLM server)
- Qdrant (Vector Database)
- n8n (Workflow automation)
- PostgreSQL (Database)

## Getting Started

### Prerequisites

- Linux or macOS with podman installed
- podman-compose installed

### Starting the Environment

To start all services:

```bash
# Make scripts executable
chmod +x *.sh

# Start all services
./startup.sh
```

By default, this will set up Gemma as your LLM model, as it's faster and smaller than alternatives like Llama.

### Changing the LLM Model

You can easily switch to a different model:

```bash
./change-model.sh MODEL_NAME
```

Available models include:
- `gemma` - Google Gemma (smaller, faster)
- `llama3` - Meta Llama 3 (larger, more powerful)
- `phi3` - Microsoft Phi-3 (smaller, faster)
- `mistral` - Mistral AI (good balance)
- `tinyllama` - Very small and fast model

After changing the model, update your n8n workflows to reference the new model name.

### Accessing Services

- n8n: http://localhost:5678
- Qdrant: http://localhost:6333
- Ollama: http://localhost:11434

## Troubleshooting

If you encounter issues:

```bash
# Check service status
./troubleshoot.sh

# Fix n8n credential issues
./fix-credentials.sh

# Fix n8n startup issues
./fix-n8n.sh

# Reset PostgreSQL data
./reset-postgres.sh
```

For more detailed logs:
```bash
podman logs -f <container-name>
```

## Service Management

- Start all services: `./startup.sh`
- Stop all services: `podman-compose down`
- Restart a specific service: `podman restart <service-name>`
