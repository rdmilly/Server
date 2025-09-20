# 🌊 Millyweb Homelab

A comprehensive, production-ready homelab infrastructure built with Docker, Traefik, and modern cloud-native technologies.

## 🏗️ Architecture Overview

### **Core Infrastructure**
- **Traefik v3** - Modern reverse proxy with automatic SSL/TLS
- **PostgreSQL + pgvector** - AI-ready database with vector search
- **MinIO** - S3-compatible object storage
- **Portainer** - Container management interface

### **AI & Development Stack**
- **Ollama + OpenWebUI** - Local LLM hosting and interface
- **LangGraph FastAPI** - AI agent framework with tool calling
- **Langfuse** - LLM observability and analytics

### **UI Components**
- **Dev Hub** - Development dashboard with agent tiles
- **Workbench** - 3-pane development environment
- **Unified Shell** - Terminal interface with HUD overlay
- **Hub Landing** - Service discovery and health monitoring

### **Supporting Services**
- **File Browser** - Web-based file management
- **ttyd** - Web terminal access
- **Grafana + cAdvisor** - Monitoring and metrics
- **n8n** - Workflow automation

## 🚀 Quick Start

1. **Clone and configure:**
   ```bash
   git clone <this-repo>
   cd millyweb-homelab
   ```

2. **Set up environment:**
   ```bash
   # Generate secrets and environment files
   chmod +x scripts/init_secrets.sh
   ./scripts/init_secrets.sh
   ```

3. **Deploy infrastructure:**
   ```bash
   # Deploy all services in correct order
   chmod +x scripts/deploy_all.sh
   ./scripts/deploy_all.sh
   ```

4. **Access services:**
   - **Hub**: https://hub.millyweb.com
   - **Dev Hub**: https://dev.millyweb.com
   - **Workbench**: https://workbench.millyweb.com
   - **Portainer**: https://port.millyweb.com

## 📁 Directory Structure

```
millyweb-homelab/
├── 📋 .gitignore                 # Git exclusions
├── 📚 README.md                  # This file
├── 📖 INSTALL.md                 # Detailed setup guide
├── 🏗️ OVERVIEW.md                # Architecture deep-dive
├── 💼 server.code-workspace      # VS Code project
├── 🐳 docker-compose.yml         # Main compose file
├── 🔄 middleware.yml             # Traefik middleware
├── 📜 scripts/                   # Deployment scripts
├── 🚦 traefik/                   # Reverse proxy config
├── 🗄️ memory/                    # Database layer
├── 📦 minio/                     # Object storage
├── 🤖 core-llm/                  # LLM services
├── 🕸️ langgraph-app/             # AI agent app
├── 👁️ observability/             # Langfuse analytics
├── 📊 monitoring/                # Grafana dashboards
├── 🔧 portainer/                 # Container management
├── 📁 filebrowser/               # File management
├── 💻 tty/                       # Web terminal
├── ⚙️ automations/               # n8n workflows
├── 🎯 dev-hub/                   # Development UI
├── 🛠️ workbench/                 # 3-pane workspace
├── 🖥️ unified-hud/               # Terminal shell
└── 🏠 hub/                       # Landing page
```

## 🔐 Security Features

- **Automatic SSL/TLS** with Let's Encrypt
- **Cloudflare DNS-01** challenge for wildcard certificates
- **Rate limiting** and DDoS protection
- **Security headers** and HSTS enforcement
- **Container resource limits** and health checks

## 🌐 Domain Configuration

Update these domains in your environment files:
- `hub.millyweb.com` - Main landing page
- `dev.millyweb.com` - Development dashboard
- `workbench.millyweb.com` - 3-pane workspace
- `shell.millyweb.com` - Terminal interface
- `port.millyweb.com` - Portainer management
- `traefik.millyweb.com` - Traefik dashboard

## 📝 Environment Variables

Key variables to configure:
```bash
CLOUDFLARE_DNS_API_TOKEN=your_token_here
ACME_EMAIL=your_email@domain.com
POSTGRES_PASSWORD=secure_random_password
MINIO_ROOT_PASSWORD=secure_random_password
```

## 🔄 Service Dependencies

Services start in this order:
1. **Traefik** - Reverse proxy (foundation)
2. **Memory** - PostgreSQL database
3. **MinIO** - Object storage
4. **Core services** - LLM, observability
5. **Applications** - LangGraph, UI components
6. **Supporting** - File browser, terminal, monitoring

## 📈 Monitoring & Observability

- **Grafana**: Container metrics and system monitoring
- **Langfuse**: LLM conversation tracking and analytics
- **Traefik Dashboard**: Request routing and SSL status
- **Portainer**: Container health and resource usage

## 🛠️ Development Workflow

1. **Local development** in `workbench.millyweb.com`
2. **Agent testing** via `dev.millyweb.com`
3. **Terminal access** through `shell.millyweb.com`
4. **File management** via browser interface
5. **Monitoring** through Grafana dashboards

## 📚 Additional Documentation

- [📖 INSTALL.md](./INSTALL.md) - Step-by-step installation
- [🏗️ OVERVIEW.md](./OVERVIEW.md) - Architecture details
- [💼 server.code-workspace](./server.code-workspace) - VS Code setup

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Test changes locally
4. Submit pull request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

For issues and questions:
1. Check the documentation in `INSTALL.md`
2. Review service logs via Portainer
3. Monitor health via Grafana dashboards

---

**🌊 Built with Modern DevOps Practices for AI-Ready Infrastructure**
