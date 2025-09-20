# 📖 Installation Guide - Millyweb Homelab

Complete step-by-step setup guide for deploying the Millyweb Homelab infrastructure.

## 🛠️ Prerequisites

### **System Requirements**
- **OS**: Ubuntu 20.04+ / Debian 11+ / CentOS 8+
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 100GB minimum, 500GB recommended
- **CPU**: 4 cores minimum, 8 cores recommended

### **Required Software**
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install Git
sudo apt install git -y

# Logout and login to apply Docker group
newgrp docker
```

### **Domain Setup**
1. **Purchase domain** (e.g., `millyweb.com`)
2. **Point to Cloudflare** nameservers
3. **Create A record** pointing to your server IP
4. **Generate API token** in Cloudflare dashboard

## 🏗️ Installation Steps

### **Step 1: Clone Repository**
```bash
cd /opt
sudo git clone <repository-url> millyweb-homelab
sudo chown -R $USER:$USER millyweb-homelab
cd millyweb-homelab
```

### **Step 2: Environment Configuration**
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Generate environment files and secrets
./scripts/init_secrets.sh
```

**Edit generated `.env` files:**
```bash
# Edit main environment
nano .env
```

**Required variables to update:**
```env
# Domain configuration
DOMAIN=millyweb.com

# Cloudflare API
CF_DNS_API_TOKEN=your_cloudflare_token_here
ACME_EMAIL=admin@millyweb.com

# Update any other generated passwords as needed
```

### **Step 3: Network Setup**
```bash
# Create external network for Traefik
docker network create traefik_net
```

### **Step 4: Deploy Infrastructure**
```bash
# Deploy all services in correct order
./scripts/deploy_all.sh
```

**The script will:**
1. ✅ Deploy Traefik (reverse proxy)
2. ✅ Deploy Memory layer (PostgreSQL)
3. ✅ Deploy MinIO (object storage)
4. ✅ Deploy Core LLM services
5. ✅ Deploy LangGraph application
6. ✅ Deploy observability services
7. ✅ Deploy UI components
8. ✅ Deploy supporting services
9. ✅ Run health checks

### **Step 5: Verify Deployment**
```bash
# Check all containers are running
docker ps

# Check service health
./scripts/health_check.sh

# View logs if needed
docker-compose logs -f service_name
```

## 🌐 Access Your Services

After successful deployment, access your services:

| Service | URL | Description |
|---------|-----|-------------|
| **Hub** | https://hub.millyweb.com | Main landing page |
| **Dev Hub** | https://dev.millyweb.com | Development dashboard |
| **Workbench** | https://workbench.millyweb.com | 3-pane workspace |
| **Shell** | https://shell.millyweb.com | Web terminal |
| **Portainer** | https://port.millyweb.com | Container management |
| **Traefik** | https://traefik.millyweb.com | Reverse proxy dashboard |
| **LLM UI** | https://llm.millyweb.com | Local LLM interface |
| **File Browser** | https://files.millyweb.com | Web file manager |
| **Grafana** | https://monitoring.millyweb.com | System metrics |
| **Langfuse** | https://observe.millyweb.com | LLM analytics |

## 🔧 Post-Installation Configuration

### **Portainer Setup**
1. Navigate to `https://port.millyweb.com`
2. Create admin account
3. Connect to local Docker environment
4. Import stack templates from `portainer/` directory

### **Grafana Setup**
1. Navigate to `https://monitoring.millyweb.com`
2. Login with admin/admin (change password)
3. Datasources should be pre-configured
4. Import dashboards from `monitoring/` directory

### **LLM Setup**
1. Navigate to `https://llm.millyweb.com`
2. Download desired models (Llama 3.1, Code Llama, etc.)
3. Configure model settings
4. Test chat functionality

### **File Browser Setup**
1. Navigate to `https://files.millyweb.com`
2. Login with admin/admin (change password)
3. Configure users and permissions
4. Set up shared workspaces

## 🔐 Security Hardening

### **SSL/TLS Verification**
```bash
# Check certificate status
curl -I https://hub.millyweb.com
openssl s_client -connect hub.millyweb.com:443 -servername hub.millyweb.com
```

### **Firewall Configuration**
```bash
# Allow only necessary ports
sudo ufw enable
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP (redirects to HTTPS)
sudo ufw allow 443/tcp   # HTTPS
sudo ufw deny 8080/tcp   # Block direct Traefik access
```

### **Container Security**
```bash
# Scan for vulnerabilities
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image $(docker images --format "{{.Repository}}:{{.Tag}}")
```

## 📊 Monitoring Setup

### **Enable Metrics Collection**
All services include:
- **Resource limits** for CPU and memory
- **Health checks** for service availability
- **Restart policies** for reliability
- **Logging configuration** for debugging

### **Grafana Dashboards**
Pre-configured dashboards for:
- Container resource usage
- Network traffic
- Storage utilization
- Application performance
- Error rates and alerts

## 🔄 Backup & Recovery

### **Database Backup**
```bash
# Automated PostgreSQL backup
docker exec memory_db_1 pg_dumpall -U postgres > backup_$(date +%Y%m%d).sql
```

### **MinIO Backup**
```bash
# Sync MinIO data
docker exec minio_server_1 mc mirror minio/artifacts /backups/artifacts
```

### **Configuration Backup**
```bash
# Backup all configs
tar -czf homelab_config_$(date +%Y%m%d).tar.gz .env* */docker-compose.yml traefik/
```

## 🐛 Troubleshooting

### **Common Issues**

**SSL Certificate Problems:**
```bash
# Check Cloudflare API token
docker-compose logs traefik | grep -i cloudflare

# Manually trigger certificate
docker exec traefik traefik healthcheck
```

**Container Won't Start:**
```bash
# Check resource usage
docker stats

# Check logs
docker-compose logs service_name

# Check port conflicts
netstat -tulpn | grep :PORT
```

**DNS Resolution Issues:**
```bash
# Test domain resolution
nslookup hub.millyweb.com
dig +trace hub.millyweb.com
```

**Database Connection Problems:**
```bash
# Test PostgreSQL connection
docker exec -it memory_db_1 psql -U postgres -l

# Check password in environment
grep POSTGRES .env
```

### **Log Locations**
- **Application logs**: `docker-compose logs`
- **Traefik logs**: Available via dashboard
- **System logs**: `/var/log/syslog`
- **Docker logs**: `journalctl -u docker`

### **Health Check Commands**
```bash
# Check all service health
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Test specific service
curl -I https://service.millyweb.com/health

# Check resource usage
docker stats --no-stream
```

## 🔄 Updates & Maintenance

### **Regular Updates**
```bash
# Update all containers
docker-compose pull
docker-compose up -d

# Clean up unused resources
docker system prune -f
```

### **Backup Before Updates**
```bash
# Full system backup
./scripts/backup_all.sh
```

### **Rolling Updates**
```bash
# Update specific service
docker-compose up -d --no-deps service_name
```

## 🆘 Getting Help

1. **Check logs** first: `docker-compose logs service_name`
2. **Verify DNS** resolution and SSL certificates
3. **Check resource** usage and available disk space
4. **Review environment** variables and configurations
5. **Test connectivity** between services

---

**✅ Installation complete! Your Millyweb Homelab is ready for development and production workloads.**
