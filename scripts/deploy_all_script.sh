#!/bin/bash

set -e

echo "🚀 Deploying Millyweb Homelab..."

# Create external network
echo "📡 Creating traefik_net network..."
docker network create traefik_net || echo "Network already exists"

# Function to wait for service health
wait_for_service() {
    local service_name=$1
    local health_url=$2
    local max_attempts=30
    local attempt=1

    echo "⏳ Waiting for $service_name to be healthy..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -k "$health_url" > /dev/null 2>&1; then
            echo "✅ $service_name is healthy"
            return 0
        fi
        
        echo "   Attempt $attempt/$max_attempts failed, retrying in 10s..."
        sleep 10
        ((attempt++))
    done
    
    echo "❌ $service_name failed to become healthy after $max_attempts attempts"
    return 1
}

# Deploy services in order
echo "🔧 Deploying Traefik..."
cd traefik && docker compose up -d && cd ..
sleep 10

echo "🔧 Deploying Portainer..."
cd portainer && docker compose up -d && cd ..

echo "🔧 Deploying Memory layer..."
cd memory && docker compose up -d && cd ..
sleep 15

echo "🔧 Deploying MinIO..."
cd minio && docker compose up -d && cd ..

echo "🔧 Deploying Core LLM stack..."
cd core-llm && docker compose up -d && cd ..
sleep 20  # Ollama takes time to start

echo "🔧 Deploying File Browser..."
cd filebrowser && docker compose up -d && cd ..

echo "🔧 Deploying Terminal..."
cd tty && docker compose up -d && cd ..

echo "🔧 Deploying Observability..."
cd observability && docker compose up -d && cd ..
sleep 15

echo "🔧 Deploying Monitoring..."
cd monitoring && docker compose up -d && cd ..

echo "🔧 Deploying Automations..."
cd automations && docker compose up -d && cd ..

echo "🔧 Deploying LangGraph App..."
cd langgraph-app && docker compose up -d && cd ..

echo "🔧 Deploying Workbench..."
cd workbench && docker compose up -d && cd ..

echo "🔧 Deploying Dev Hub..."
cd dev-hub && docker compose up -d && cd ..

echo "🔧 Deploying Unified HUD..."
cd unified-hud/shell && docker compose up -d && cd ../..

echo "🔧 Deploying Hub..."
cd hub && docker compose up -d && cd ..

echo ""
echo "🎉 Deployment complete!"
echo ""
echo "📋 Service URLs (after Cloudflare Access SSO):"
echo "   🏠 Hub:           https://hub.millyweb.com"
echo "   🔧 Dev Hub:       https://devhub.millyweb.com"
echo "   💬 OpenWebUI:     https://openwebui.millyweb.com"
echo "   🤖 LangGraph:     https://agents.millyweb.com"
echo "   📁 Files:         https://files.millyweb.com"
echo "   💻 Terminal:      https://term.millyweb.com"
echo "   🗄️  MinIO:         https://minio.millyweb.com"
echo "   📊 Grafana:       https://grafana.millyweb.com"
echo "   🐳 Portainer:     https://port.millyweb.com"
echo "   📈 Langfuse:      https://logs.millyweb.com"
echo ""
echo "🧪 Health check URLs:"
echo "   curl -k https://agents.millyweb.com/health"
echo "   curl -k https://hub.millyweb.com"
echo ""
echo "⚠️  Remember to:"
echo "   1. Configure Cloudflare Access for *.millyweb.com"
echo "   2. Set your Google email in Cloudflare Access policies"
echo "   3. Download Ollama models: docker exec -it core-llm-ollama-1 ollama pull llama2"
echo "   4. Create MinIO buckets: artifacts, documents, datasets, models"