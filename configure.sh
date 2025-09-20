#!/bin/bash

# 🌊 Millyweb Homelab - Environment Configuration Script
echo "🌊 Millyweb Homelab - Initial Configuration"
echo "=========================================="

# Create .env file
cat > .env << EOF
# 🌐 Domain Configuration
DOMAIN=millyweb.com
# ⚠️  CHANGE THIS TO YOUR ACTUAL DOMAIN!

# 🔐 Cloudflare Configuration
CF_DNS_API_TOKEN=your_cloudflare_api_token_here
# ⚠️  Get this from Cloudflare Dashboard > My Profile > API Tokens

# 📧 Let's Encrypt Email
ACME_EMAIL=admin@millyweb.com
# ⚠️  CHANGE THIS TO YOUR ACTUAL EMAIL!

# 🗄️ Database Passwords (Auto-generated)
POSTGRES_PASSWORD=$(openssl rand -base64 32)
POSTGRES_USER=homelab
POSTGRES_DB=homelab

# 📦 MinIO Configuration (Auto-generated)
MINIO_ROOT_USER=admin
MINIO_ROOT_PASSWORD=$(openssl rand -base64 32)

# 🤖 LangGraph Configuration
LANGFUSE_SECRET_KEY=$(openssl rand -base64 32)
LANGFUSE_PUBLIC_KEY=$(openssl rand -base64 16)

# 🔒 General Security
SECRET_KEY=$(openssl rand -base64 32)

# 🐳 Docker Configuration
COMPOSE_PROJECT_NAME=millyweb-homelab
EOF

echo "✅ Created .env file with auto-generated passwords"
echo ""
echo "⚠️  IMPORTANT: You MUST edit .env and update:"
echo "   - DOMAIN (replace millyweb.com)"
echo "   - CF_DNS_API_TOKEN (from Cloudflare)"
echo "   - ACME_EMAIL (your email address)"
echo ""
echo "🔧 To edit: nano .env"
echo ""

# Create domain replacement script
cat > update_domains.sh << 'EOF'
#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 your-domain.com"
    echo "This will replace millyweb.com with your domain in all files"
    exit 1
fi

NEW_DOMAIN=$1
OLD_DOMAIN="millyweb.com"

echo "🔄 Updating domain from $OLD_DOMAIN to $NEW_DOMAIN..."

# Find and replace in all docker-compose files
find . -name "docker-compose.yml" -exec sed -i "s/$OLD_DOMAIN/$NEW_DOMAIN/g" {} \;

# Update Traefik dynamic config
find . -name "middleware.yml" -exec sed -i "s/$OLD_DOMAIN/$NEW_DOMAIN/g" {} \;

# Update HTML files
find . -name "*.html" -exec sed -i "s/$OLD_DOMAIN/$NEW_DOMAIN/g" {} \;

# Update environment file
sed -i "s/$OLD_DOMAIN/$NEW_DOMAIN/g" .env

echo "✅ Domain updated in all configuration files"
echo "🔧 Don't forget to:"
echo "   1. Update your DNS records"
echo "   2. Set your Cloudflare API token in .env"
echo "   3. Update ACME_EMAIL in .env"
EOF

chmod +x update_domains.sh

echo "✅ Created update_domains.sh script"
echo "🔧 Usage: ./update_domains.sh yourdomain.com"
echo ""

# Create secrets verification script
cat > verify_config.sh << 'EOF'
#!/bin/bash

echo "🔍 Verifying Configuration..."
echo "=========================="

# Check if .env exists
if [ ! -f .env ]; then
    echo "❌ .env file not found!"
    exit 1
fi

# Source the .env file
source .env

# Check critical variables
echo "📋 Configuration Status:"
echo ""

if [ "$DOMAIN" = "millyweb.com" ]; then
    echo "❌ DOMAIN: Still using default (millyweb.com)"
    NEEDS_UPDATE=true
else
    echo "✅ DOMAIN: $DOMAIN"
fi

if [ "$CF_DNS_API_TOKEN" = "your_cloudflare_api_token_here" ]; then
    echo "❌ CF_DNS_API_TOKEN: Not configured"
    NEEDS_UPDATE=true
else
    echo "✅ CF_DNS_API_TOKEN: Configured"
fi

if [ "$ACME_EMAIL" = "admin@millyweb.com" ]; then
    echo "❌ ACME_EMAIL: Using default email"
    NEEDS_UPDATE=true
else
    echo "✅ ACME_EMAIL: $ACME_EMAIL"
fi

echo "✅ POSTGRES_PASSWORD: Auto-generated"
echo "✅ MINIO_ROOT_PASSWORD: Auto-generated"
echo "✅ SECRET_KEY: Auto-generated"

echo ""

if [ "$NEEDS_UPDATE" = true ]; then
    echo "⚠️  Configuration needs updates!"
    echo "🔧 Edit with: nano .env"
    echo "🔧 Update domain with: ./update_domains.sh yourdomain.com"
else
    echo "✅ Configuration looks good!"
fi
EOF

chmod +x verify_config.sh

echo "✅ Created verify_config.sh script"
echo "🔧 Usage: ./verify_config.sh"
echo ""
echo "🚀 Next steps:"
echo "   1. ./update_domains.sh yourdomain.com"
echo "   2. nano .env (update API token and email)"
echo "   3. ./verify_config.sh"
echo "   4. Ready to deploy!"
