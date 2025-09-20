#!/bin/bash

set -e

echo "🐳 Initializing Millyweb Homelab for Portainer deployment..."

# Create directory structure
mkdir -p /srv/traefik
mkdir -p /srv/workspaces
sudo chown -R 1000:1000 /srv/workspaces

# Generate secure random values
generate_secret() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Generate all secrets
MEMORY_PASSWORD=$(generate_secret)
MINIO_PASSWORD=$(generate_secret)
LANGFUSE_SECRET=$(generate_secret)
LANGFUSE_DB_PASSWORD=$(generate_secret)
NEXTAUTH_SECRET=$(generate_secret)
SALT=$(generate_secret)
ENCRYPTION_KEY=$(openssl rand -hex 32)

echo "🔑 Generated secure passwords"

# Create .env files
cat > traefik/.env << EOF
CF_DNS_API_TOKEN=CHANGE_ME
ACME_EMAIL=admin@millyweb.com
DOMAIN=millyweb.com
EOF

cat > memory/.env << EOF
POSTGRES_DB=chat
POSTGRES_USER=chat
POSTGRES_PASSWORD=${MEMORY_PASSWORD}
PGDATA=/var/lib/postgresql/data/pgdata
EOF

cat > minio/.env << EOF
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=${MINIO_PASSWORD}
MINIO_CONSOLE_ADDRESS=:9001
EOF

cat > observability/.env << EOF
NEXTAUTH_SECRET=${NEXTAUTH_SECRET}
SALT=${SALT}
ENCRYPTION_KEY=${ENCRYPTION_KEY}
LANGFUSE_SECRET_KEY=lf_sk_${LANGFUSE_SECRET}
LANGFUSE_PUBLIC_KEY=lf_pk_${LANGFUSE_SECRET}
DATABASE_URL=postgresql://langfuse:${LANGFUSE_DB_PASSWORD}@postgres:5432/langfuse
NEXTAUTH_URL=https://logs.millyweb.com
POSTGRES_USER=langfuse
POSTGRES_PASSWORD=${LANGFUSE_DB_PASSWORD}
POSTGRES_DB=langfuse
EOF

cat > langgraph-app/.env << EOF
POSTGRES_HOST=memory-postgres-1
POSTGRES_PORT=5432
POSTGRES_DB=chat
POSTGRES_USER=chat
POSTGRES_PASSWORD=${MEMORY_PASSWORD}
MINIO_ENDPOINT=minio-server-1:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=${MINIO_PASSWORD}
LANGFUSE_SECRET_KEY=lf_sk_${LANGFUSE_SECRET}
LANGFUSE_PUBLIC_KEY=lf_pk_${LANGFUSE_SECRET}
LANGFUSE_HOST=https://logs.millyweb.com
OLLAMA_BASE_URL=http://core-llm-ollama-1:11434
EOF

# Create Portainer environment variable files for easy copy-paste
echo "📝 Creating Portainer-ready environment variable files..."

cat > PORTAINER-ENV-traefik.txt << EOF
# Copy this into Portainer Stack Environment Variables for 'traefik' stack
CF_DNS_API_TOKEN=CHANGE_ME
ACME_EMAIL=admin@millyweb.com
DOMAIN=millyweb.com
EOF

cat > PORTAINER-ENV-memory.txt << EOF
# Copy this into Portainer Stack Environment Variables for 'memory' stack
POSTGRES_DB=chat
POSTGRES_USER=chat
POSTGRES_PASSWORD=${MEMORY_PASSWORD}
PGDATA=/var/lib/postgresql/data/pgdata
EOF

cat > PORTAINER-ENV-minio.txt << EOF
# Copy this into Portainer Stack Environment Variables for 'minio' stack
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=${MINIO_PASSWORD}
MINIO_CONSOLE_ADDRESS=:9001
EOF

cat > PORTAINER-ENV-observability.txt << EOF
# Copy this into Portainer Stack Environment Variables for 'observability' stack
NEXTAUTH_SECRET=${NEXTAUTH_SECRET}
SALT=${SALT}
ENCRYPTION_KEY=${ENCRYPTION_KEY}
LANGFUSE_SECRET_KEY=lf_sk_${LANGFUSE_SECRET}
LANGFUSE_PUBLIC_KEY=lf_pk_${LANGFUSE_SECRET}
DATABASE_URL=postgresql://langfuse:${LANGFUSE_DB_PASSWORD}@postgres:5432/langfuse
NEXTAUTH_URL=https://logs.millyweb.com
POSTGRES_USER=langfuse
POSTGRES_PASSWORD=${LANGFUSE_DB_PASSWORD}
POSTGRES_DB=langfuse
EOF

cat > PORTAINER-ENV-langgraph-app.txt << EOF
# Copy this into Portainer Stack Environment Variables for 'langgraph-app' stack
POSTGRES_HOST=memory-postgres-1
POSTGRES_PORT=5432
POSTGRES_DB=chat
POSTGRES_USER=chat
POSTGRES_PASSWORD=${MEMORY_PASSWORD}
MINIO_ENDPOINT=minio-server-1:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=${MINIO_PASSWORD}
LANGFUSE_SECRET_KEY=lf_sk_${LANGFUSE_SECRET}
LANGFUSE_PUBLIC_KEY=lf_pk_${LANGFUSE_SECRET}
LANGFUSE_HOST=https://logs.millyweb.com
OLLAMA_BASE_URL=http://core-llm-ollama-1:11434
EOF

# Create network
echo "🌐 Creating Docker network..."
docker network create traefik_net || echo "Network already exists"

# Deploy foundation services (Traefik + Portainer)
echo "🚀 Deploying foundation services..."

if [ -d "traefik" ] && [ -f "traefik/docker-compose.yml" ]; then
    echo "📡 Starting Traefik..."
    cd traefik && docker compose up -d && cd ..
    sleep 5
fi

if [ -d "portainer" ] && [ -f "portainer/docker-compose.yml" ]; then
    echo "🐳 Starting Portainer..."
    cd portainer && docker compose up -d && cd ..
    sleep 5
fi

echo ""
echo "✅ Foundation setup complete!"
echo ""
echo "🔧 Next steps:"
echo "   1. Edit traefik/.env and set your Cloudflare API token"
echo "   2. Access Portainer at your-server-ip:9000"
echo "   3. Use the PORTAINER-ENV-*.txt files to copy environment variables"
echo "   4. Deploy each service as a separate stack in Portainer"
echo ""
echo "📋 Recommended Portainer Stack Order:"
echo "   1. traefik (foundation - may already be running)"
echo "   2. memory (PostgreSQL database)"
echo "   3. minio (object storage)"
echo "   4. core-llm (Ollama + OpenWebUI)"
echo "   5. observability (Langfuse)"
echo "   6. langgraph-app (AI agents)"
echo "   7. filebrowser, tty, monitoring, etc."
echo "   8. workbench, dev-hub, hub (UI components)"
echo ""
echo "🔑 Environment variable files created:"
ls -la PORTAINER-ENV-*.txt
echo ""
echo "⚠️  Keep these files secure - they contain passwords!"