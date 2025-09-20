#!/bin/bash

set -e

echo "🔧 Initializing Millyweb Homelab secrets..."

# Create directory structure
mkdir -p /srv/traefik
mkdir -p /srv/workspaces
sudo chown -R 1000:1000 /srv/workspaces

# Generate secure random values
generate_secret() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Traefik configuration
cat > traefik/.env << EOF
CF_DNS_API_TOKEN=CHANGE_ME
ACME_EMAIL=admin@millyweb.com
DOMAIN=millyweb.com
EOF

# Memory database
cat > memory/.env << EOF
POSTGRES_DB=chat
POSTGRES_USER=chat
POSTGRES_PASSWORD=$(generate_secret)
PGDATA=/var/lib/postgresql/data/pgdata
EOF

# MinIO object storage
cat > minio/.env << EOF
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=$(generate_secret)
MINIO_CONSOLE_ADDRESS=:9001
EOF

# Observability (Langfuse)
cat > observability/.env << EOF
NEXTAUTH_SECRET=$(generate_secret)
SALT=$(generate_secret)
ENCRYPTION_KEY=$(openssl rand -hex 32)
LANGFUSE_SECRET_KEY=lf_sk_$(generate_secret)
LANGFUSE_PUBLIC_KEY=lf_pk_$(generate_secret)
DATABASE_URL=postgresql://langfuse:$(generate_secret)@postgres:5432/langfuse
NEXTAUTH_URL=https://logs.millyweb.com
POSTGRES_USER=langfuse
POSTGRES_PASSWORD=$(generate_secret)
POSTGRES_DB=langfuse
EOF

# LangGraph app configuration
cat > langgraph-app/.env << EOF
POSTGRES_HOST=memory-postgres-1
POSTGRES_PORT=5432
POSTGRES_DB=chat
POSTGRES_USER=chat
POSTGRES_PASSWORD=CHANGE_ME_MATCH_MEMORY
MINIO_ENDPOINT=minio-server-1:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=CHANGE_ME_MATCH_MINIO
LANGFUSE_SECRET_KEY=CHANGE_ME_MATCH_OBSERVABILITY
LANGFUSE_PUBLIC_KEY=CHANGE_ME_MATCH_OBSERVABILITY
LANGFUSE_HOST=https://logs.millyweb.com
OLLAMA_BASE_URL=http://core-llm-ollama-1:11434
EOF

echo "✅ Secret files created!"
echo "📝 Next steps:"
echo "   1. Edit traefik/.env and set your Cloudflare API token"
echo "   2. Update other CHANGE_ME values as needed"
echo "   3. Run ./scripts/deploy_all.sh"
echo ""
echo "🔑 Keep these files secure and never commit them to git!"