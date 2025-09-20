# Millyweb Homelab / Dev Hub

A single-node homelab with integrated AI/LLM development environment, featuring multiple UI modes and comprehensive tooling.

## Quick Start

1. **Prerequisites**
   - Docker & Docker Compose v2
   - Domain pointed to your server: `millyweb.com`
   - Cloudflare account with DNS management
   - 4+ GB RAM, 2+ CPU cores recommended

2. **Setup**
   ```bash
   git clone <this-repo>
   cd millyweb-homelab
   chmod +x scripts/*.sh
   ./scripts/init_secrets.sh
   # Edit .env files to replace CHANGE_ME values
   ./scripts/deploy_all.sh
   ```

3. **Access**
   - Hub: https://hub.millyweb.com
   - Dev Hub: https://devhub.millyweb.com
   - OpenWebUI: https://openwebui.millyweb.com
   - All services protected by Cloudflare Access SSO

## Services

| Service | URL | Description |
|---------|-----|-------------|
| Hub | hub.millyweb.com | Main landing page |
| Dev Hub | devhub.millyweb.com | Integrated development interface |
| OpenWebUI | openwebui.millyweb.com | LLM chat interface |
| LangGraph | agents.millyweb.com | AI agent backend |
| File Browser | files.millyweb.com | Workspace file management |
| Terminal | term.millyweb.com | Web-based shell |
| MinIO | minio.millyweb.com | Object storage |
| Grafana | grafana.millyweb.com | Monitoring dashboards |
| Portainer | port.millyweb.com | Container management |
| Langfuse | logs.millyweb.com | LLM observability |

## Architecture

```
[ Internet ] 
     |
 [ Cloudflare (DNS + Access + TLS) ]
     |
 [ Traefik v3 :80/:443 ]  -- docker network -->  traefik_net
     |                         |        |        |          |
  openwebui   langgraph-app   filebrowser  ttyd  grafana   portainer  minio  langfuse
     |             |               |         |       |         |         |       |
   Ollama        Postgres (pgvector)       Workspaces (/srv/workspaces)       Langfuse-DB
```

## Acceptance Tests

After deployment, verify:

- ✅ https://hub.millyweb.com loads after Cloudflare Access SSO
- ✅ https://devhub.millyweb.com switches Office/Build layouts; panes load
- ✅ https://shell.millyweb.com/embed/openwebui shows HUD bar on top
- ✅ https://agents.millyweb.com/health → {"ok": true}
- ✅ https://openwebui.millyweb.com can talk to an Ollama model
- ✅ https://files.millyweb.com shows /srv/workspaces and can create a file
- ✅ https://term.millyweb.com opens a shell; pwd is /workspaces
- ✅ https://minio.millyweb.com lets you create artifacts, documents, datasets, models buckets

## Troubleshooting

1. **Services not accessible**: Check Traefik logs and DNS propagation
2. **SSL issues**: Verify Cloudflare API token and DNS-01 challenge
3. **SSO problems**: Confirm Cloudflare Access configuration
4. **Resource issues**: Monitor with Grafana, adjust container limits

See INSTALL.md for detailed setup instructions and OVERVIEW.md for architecture details.