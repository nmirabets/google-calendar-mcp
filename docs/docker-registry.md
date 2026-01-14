# Using the Published Docker Image

The Google Calendar MCP Server is automatically published to GitHub Container Registry (ghcr.io) whenever changes are pushed to the main branch.

## Quick Start

### Pull the Image

```bash
docker pull ghcr.io/nmirabets/google-calendar-mcp:latest
```

### Run with JSON Credentials (Recommended)

```bash
docker run -d \
  --name calendar-mcp \
  --env GOOGLE_OAUTH_CREDENTIALS_JSON='{"installed":{"client_id":"YOUR_CLIENT_ID","client_secret":"YOUR_SECRET","redirect_uris":["http://localhost:3500/oauth2callback"]}}' \
  --env TRANSPORT=http \
  --env HOST=0.0.0.0 \
  --env PORT=3000 \
  -p 3000:3000 \
  -p 3500:3500 \
  -v calendar-tokens:/home/nodejs/.config/google-calendar-mcp \
  ghcr.io/nmirabets/google-calendar-mcp:latest
```

### Authenticate

```bash
docker exec -it calendar-mcp npm run auth
```

## Available Tags

- `latest` - Latest build from main branch
- `X.Y.Z` - Specific version tags (e.g., `2.3.1`)
- `X.Y` - Major.minor version (e.g., `2.3`)
- `X` - Major version (e.g., `2`)
- `main-<sha>` - Specific commit SHA

## Usage Examples

### 1. Docker Compose

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  calendar-mcp:
    image: ghcr.io/nmirabets/google-calendar-mcp:latest
    container_name: calendar-mcp
    restart: unless-stopped
    
    environment:
      # JSON credentials (recommended)
      GOOGLE_OAUTH_CREDENTIALS_JSON: '{"installed":{"client_id":"YOUR_CLIENT_ID","client_secret":"YOUR_SECRET","redirect_uris":["http://localhost:3500/oauth2callback"]}}'
      TRANSPORT: stdio  # or 'http' for HTTP mode
      
    volumes:
      - calendar-tokens:/home/nodejs/.config/google-calendar-mcp
    
    ports:
      - "3000:3000"  # HTTP mode (if TRANSPORT=http)
      - "3500:3500"  # OAuth authentication
      - "3501:3501"  # Multi-account support
      - "3502:3502"
      - "3503:3503"
      - "3504:3504"
      - "3505:3505"

volumes:
  calendar-tokens:
```

Create `.env` file:
```bash
GOOGLE_OAUTH_CREDENTIALS_JSON={"installed":{"client_id":"...","client_secret":"...","redirect_uris":["..."]}}
```

Run:
```bash
docker compose up -d
docker compose exec calendar-mcp npm run auth
```

### 2. Claude Desktop Integration (stdio mode)

Add to your Claude Desktop config:

**macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
**Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "google-calendar": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "--env", "GOOGLE_OAUTH_CREDENTIALS_JSON={\"installed\":{\"client_id\":\"YOUR_CLIENT_ID\",\"client_secret\":\"YOUR_SECRET\",\"redirect_uris\":[\"http://localhost:3500/oauth2callback\"]}}",
        "--mount", "type=volume,src=calendar-tokens,dst=/home/nodejs/.config/google-calendar-mcp",
        "ghcr.io/nmirabets/google-calendar-mcp:latest"
      ]
    }
  }
}
```

### 3. Kubernetes Deployment

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: google-calendar-credentials
type: Opaque
stringData:
  credentials.json: |
    {"installed":{"client_id":"YOUR_CLIENT_ID","client_secret":"YOUR_SECRET","redirect_uris":["http://localhost:3500/oauth2callback"]}}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: calendar-mcp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: calendar-mcp
  template:
    metadata:
      labels:
        app: calendar-mcp
    spec:
      containers:
      - name: server
        image: ghcr.io/nmirabets/google-calendar-mcp:latest
        env:
        - name: GOOGLE_OAUTH_CREDENTIALS_JSON
          valueFrom:
            secretKeyRef:
              name: google-calendar-credentials
              key: credentials.json
        - name: TRANSPORT
          value: "http"
        - name: HOST
          value: "0.0.0.0"
        - name: PORT
          value: "3000"
        ports:
        - containerPort: 3000
        - containerPort: 3500
        volumeMounts:
        - name: tokens
          mountPath: /home/nodejs/.config/google-calendar-mcp
      volumes:
      - name: tokens
        persistentVolumeClaim:
          claimName: calendar-tokens
---
apiVersion: v1
kind: Service
metadata:
  name: calendar-mcp
spec:
  selector:
    app: calendar-mcp
  ports:
  - name: http
    port: 3000
    targetPort: 3000
  - name: oauth
    port: 3500
    targetPort: 3500
```

### 4. HTTP Mode Testing

```bash
# Start in HTTP mode
docker run -d \
  --name calendar-mcp \
  --env GOOGLE_OAUTH_CREDENTIALS_JSON='{"installed":{...}}' \
  --env TRANSPORT=http \
  --env HOST=0.0.0.0 \
  --env PORT=3000 \
  -p 3000:3000 \
  -p 3500:3500 \
  -v calendar-tokens:/home/nodejs/.config/google-calendar-mcp \
  ghcr.io/nmirabets/google-calendar-mcp:latest

# Authenticate
docker exec -it calendar-mcp npm run auth

# Test health endpoint
curl http://localhost:3000/health

# List available tools
curl -X POST http://localhost:3000 \
  -H "Content-Type: application/json" \
  -H "Accept: application/json,text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
```

## Platform Support

The Docker images are built for multiple platforms:
- `linux/amd64` - Intel/AMD 64-bit
- `linux/arm64` - ARM 64-bit (Apple Silicon, AWS Graviton, etc.)

Docker automatically pulls the correct image for your platform.

## Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `GOOGLE_OAUTH_CREDENTIALS_JSON` | OAuth credentials as JSON string | - | Yes* |
| `GOOGLE_OAUTH_CREDENTIALS` | Path to credentials file | `gcp-oauth.keys.json` | Yes* |
| `TRANSPORT` | Communication mode: `stdio` or `http` | `stdio` | No |
| `HOST` | Server host (HTTP mode only) | `127.0.0.1` | No |
| `PORT` | Server port (HTTP mode only) | `3000` | No |
| `GOOGLE_CALENDAR_MCP_TOKEN_PATH` | Custom token storage path | `~/.config/google-calendar-mcp/tokens.json` | No |

*Either `GOOGLE_OAUTH_CREDENTIALS_JSON` or `GOOGLE_OAUTH_CREDENTIALS` must be provided.

## Volume Mounts

- `/home/nodejs/.config/google-calendar-mcp` - OAuth tokens storage (recommended to persist)
- `/app/gcp-oauth.keys.json` - Credentials file (if using file-based credentials)

## Ports

- `3000` - HTTP mode server (default, configurable via PORT env var)
- `3500-3505` - OAuth authentication callbacks (multi-account support)

## Security Notes

1. **Never expose HTTP mode to the internet** - It has no authentication layer
2. **Use JSON credentials with secrets management** - More secure than mounting files
3. **Persist tokens volume** - Avoid re-authentication on every restart
4. **Use specific version tags in production** - Avoid `latest` tag

## Troubleshooting

### Image Pull Issues

```bash
# Login to GitHub Container Registry (if image is private)
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Pull with specific tag
docker pull ghcr.io/nmirabets/google-calendar-mcp:2.3.1
```

### Container Won't Start

```bash
# Check logs
docker logs calendar-mcp

# Common issues:
# 1. Missing credentials - set GOOGLE_OAUTH_CREDENTIALS_JSON
# 2. Port conflict - change -p 3000:3000 to -p 3010:3000
# 3. Invalid JSON - validate your credentials JSON
```

### Authentication Failed

```bash
# Remove old tokens and re-authenticate
docker volume rm calendar-tokens
docker exec -it calendar-mcp npm run auth
```

## Updates

To update to the latest version:

```bash
docker pull ghcr.io/nmirabets/google-calendar-mcp:latest
docker stop calendar-mcp
docker rm calendar-mcp
# Run your docker run command again
```

With Docker Compose:
```bash
docker compose pull
docker compose up -d
```

## GitHub Container Registry

The images are publicly available at:
**https://github.com/nmirabets/google-calendar-mcp/pkgs/container/google-calendar-mcp**

All builds are automatically signed and include attestations for supply chain security.

