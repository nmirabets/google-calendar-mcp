# Docker Deployment Guide

Simple, production-ready Docker setup for the Google Calendar MCP Server. Follow the quick start guide if you already have the project downloaded.

## Quick Start 

```bash
# 1. Place OAuth credentials in project root
# * optional if you have already placed the file in the root of this project folder
cp /path/to/your/gcp-oauth.keys.json ./gcp-oauth.keys.json

# Ensure the file has correct permissions for Docker to read
chmod 644 ./gcp-oauth.keys.json

# 2. Configure environment (optional - uses stdio mode by default)
# The .env.example file contains all defaults. Copy if customization needed:
cp .env.example .env

# 3. Build and start the server
docker compose up -d

# 4. Authenticate (one-time setup)
# This will show the authentication URL that needs to be
# visited to give authorization to the application.
# Visit the URL and complete the OAuth process.
# Note: This runs the built auth-server.js (build happens during docker build)
docker compose exec calendar-mcp npm run auth
# Note: This step only needs to be done once unless the app is in testing mode
# in which case the tokens expire after 7 days 

# 5. Manage accounts from your browser
# Visit http://localhost:3000/accounts to add, re-authenticate, or remove accounts

# 5. Add to Claude Desktop config (see stdio Mode section below)
```

## Credentials Configuration Options

You can provide OAuth credentials to the Docker container using one of two methods:

### Option 1: JSON Environment Variable (Recommended for Docker)

**Advantages:**
- No file mounting needed
- Works seamlessly with secrets management systems (Kubernetes secrets, Docker secrets, etc.)
- Simpler Docker Compose configuration
- More secure (credentials not stored in filesystem)

**Setup:**

1. Add your credentials as a JSON string in your `.env` file:

```bash
# In .env file
GOOGLE_OAUTH_CREDENTIALS_JSON='{"installed":{"client_id":"your-client-id.apps.googleusercontent.com","client_secret":"your-secret","redirect_uris":["http://localhost:3500/oauth2callback"]}}'
```

2. Update `docker-compose.yml` to remove the credentials file mount:

```yaml
services:
  calendar-mcp:
    build: .
    container_name: calendar-mcp
    restart: unless-stopped
    
    env_file: .env
    
    # OAuth credentials via environment variable - no file mount needed!
    volumes:
      # Remove or comment out: - ./gcp-oauth.keys.json:/app/gcp-oauth.keys.json:ro
      - calendar-tokens:/home/nodejs/.config/google-calendar-mcp
```

3. Build and start:

```bash
docker compose up -d
docker compose exec calendar-mcp npm run auth
```

**Alternative format (direct, without "installed" wrapper):**

```bash
GOOGLE_OAUTH_CREDENTIALS_JSON='{"client_id":"your-client-id.apps.googleusercontent.com","client_secret":"your-secret","redirect_uris":["http://localhost:3500/oauth2callback"]}'
```

### Option 2: File Mount (Traditional)

Mount the credentials file as shown in the Quick Start section above. This method is simpler for local development where you already have the credentials file.

```yaml
volumes:
  - ./gcp-oauth.keys.json:/app/gcp-oauth.keys.json:ro
  - calendar-tokens:/home/nodejs/.config/google-calendar-mcp
```

## Two Modes

The server supports two transport modes: **stdio** (for local Claude Desktop) and **HTTP** (for local development/testing).

> **⚠️ Security Note:** HTTP mode is designed for **localhost-only** development and testing. It does not include authentication and should never be exposed to untrusted networks. For production use with Claude Desktop, always use **stdio mode**.

### stdio Mode (Recommended for Claude Desktop)
**Direct process integration for Claude Desktop:**

#### Step 1: Initial Setup
```bash
# Clone and setup
git clone https://github.com/nspady/google-calendar-mcp.git
cd google-calendar-mcp

# Place your OAuth credentials in the project root
cp /path/to/your/gcp-oauth.keys.json ./gcp-oauth.keys.json

# Ensure the file has correct permissions for Docker to read
chmod 644 ./gcp-oauth.keys.json

# Build and start the container
docker compose up -d

# Authenticate (one-time setup)
# Note: This runs the built auth-server.js (build happens during docker build)
docker compose exec calendar-mcp npm run auth
```

#### Step 2: Claude Desktop Configuration
Add to your Claude Desktop config file:

**macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
**Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

**Option A: Using JSON Environment Variable (Recommended)**

```json
{
  "mcpServers": {
    "google-calendar": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "--env", "GOOGLE_OAUTH_CREDENTIALS_JSON={\"installed\":{\"client_id\":\"your-client-id\",\"client_secret\":\"your-secret\",\"redirect_uris\":[\"http://localhost:3500/oauth2callback\"]}}",
        "--mount", "type=volume,src=google-calendar-mcp_calendar-tokens,dst=/home/nodejs/.config/google-calendar-mcp",
        "calendar-mcp"
      ]
    }
  }
}
```

**⚠️ Important**: Replace the JSON credentials with your actual OAuth credentials. Make sure to escape quotes properly in the JSON config.

**Option B: Using File Mount (Traditional)**

```json
{
  "mcpServers": {
    "google-calendar": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "--mount", "type=bind,src=/absolute/path/to/your/gcp-oauth.keys.json,dst=/app/gcp-oauth.keys.json",
        "--mount", "type=volume,src=google-calendar-mcp_calendar-tokens,dst=/home/nodejs/.config/google-calendar-mcp",
        "calendar-mcp"
      ]
    }
  }
}
```

**⚠️ Important**: Replace `/absolute/path/to/your/gcp-oauth.keys.json` with the actual absolute path to your credentials file.

#### Step 3: Restart Claude Desktop
Restart Claude Desktop to load the new configuration. The server should now work without authentication prompts.

### HTTP Mode (Local Development Only)
**For local testing, debugging, and development (Claude Desktop uses stdio):**

> **Important:** HTTP mode binds to `127.0.0.1` by default and is only accessible from localhost. This is intentional for security - the server has no authentication layer.

#### Step 1: Configure Environment
```bash
# Clone and setup
git clone https://github.com/nspady/google-calendar-mcp.git
cd google-calendar-mcp

# Place your OAuth credentials in the project root
cp /path/to/your/gcp-oauth.keys.json ./gcp-oauth.keys.json

# Ensure the file has correct permissions for Docker to read
chmod 644 ./gcp-oauth.keys.json

# Configure for HTTP mode
# Copy .env.example which has defaults (TRANSPORT=stdio, HOST=127.0.0.1, PORT=3000)
cp .env.example .env

# Change TRANSPORT to http (other defaults are already correct)
# Update TRANSPORT=stdio to TRANSPORT=http in .env
# Note: HOST defaults to 127.0.0.1 for security (localhost only)

```

#### Step 2: Start and Authenticate
```bash
# Build and start the server in HTTP mode
docker compose up -d

# Authenticate (one-time setup)
# Note: This runs the built auth-server.js (build happens during docker build)
docker compose exec calendar-mcp npm run auth
# This will show authentication URLs (visit the displayed URL)
# This step only needs to be done once unless the app is in testing mode
# in which case the tokens expire after 7 days 

# Verify server is running
curl http://localhost:3000/health
# Should return: {"status":"healthy","server":"google-calendar-mcp","timestamp":"YYYY-MM-DDT00:00:00.000"}
```

#### Step 3: Test with cURL Example
```bash
# Run comprehensive HTTP tests
bash examples/http-with-curl.sh

# Or test specific endpoint
bash examples/http-with-curl.sh http://localhost:3000
```

#### Step 4: Claude Desktop HTTP Configuration
Add to your Claude Desktop config file:

**macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
**Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "google-calendar": {
      "command": "mcp-client",
      "args": ["http://localhost:3000"]
    }
  }
}
```

**Note**: HTTP mode requires the container to be running (`docker compose up -d`)

## Development: Updating Code

If you modify the source code and want to see your changes reflected in the Docker container:

```bash
# Rebuild the Docker image and restart the container
docker compose build && docker compose up -d

# Verify changes are applied (check timestamp updates)
curl http://localhost:3000/health
```

**Why rebuild?** The Docker image contains a built snapshot of your code. Changes to source files won't appear until you rebuild the image with `docker compose build`.
