# SSH Port Forwarding for Headless Server Authentication

## Problem
You need to authenticate the MCP server on a headless server (no browser), but OAuth requires browser interaction.

## Solution: SSH Port Forwarding

### Step 1: Start MCP Server on Remote Server
```bash
# On your server
docker run -d \
  --name calendar-mcp \
  --env GOOGLE_OAUTH_CREDENTIALS_JSON='{"installed":{...}}' \
  -p 3500:3500 \
  -v calendar-tokens:/home/nodejs/.config/google-calendar-mcp \
  ghcr.io/nmirabets/google-calendar-mcp:latest

# Start authentication (will wait for callback)
docker exec calendar-mcp npm run auth
```

### Step 2: Create SSH Tunnel from Local Machine
```bash
# On your LOCAL machine, in a NEW terminal
ssh -L 3500:localhost:3500 user@your-server.com
```

This forwards `localhost:3500` on your local machine to `localhost:3500` on the server.

### Step 3: Open Browser Locally
The authentication server on the remote machine will give you a URL like:
```
http://localhost:3500
```

Open this URL in YOUR LOCAL browser. Because of the SSH tunnel, it will connect to the server's authentication endpoint.

### Step 4: Complete OAuth Flow
- Click "Authenticate" in your local browser
- Complete Google OAuth
- Tokens are saved on the SERVER

### Step 5: Close Tunnel
```bash
# Press Ctrl+C in the SSH tunnel terminal
```

The server now has valid tokens and can run headless!

## Example Complete Flow

**Terminal 1 (Server):**
```bash
ssh user@server.com
docker run -d --name calendar-mcp \
  --env GOOGLE_OAUTH_CREDENTIALS_JSON='{"installed":{...}}' \
  -p 3500:3500 \
  -v calendar-tokens:/home/nodejs/.config/google-calendar-mcp \
  ghcr.io/nmirabets/google-calendar-mcp:latest
docker exec calendar-mcp npm run auth
# Leaves this running, waiting for callback...
```

**Terminal 2 (Local):**
```bash
ssh -L 3500:localhost:3500 user@server.com
# Opens http://localhost:3500 in browser
# Completes authentication
# Press Ctrl+C when done
```

**Back to Terminal 1:**
```
# Authentication completes automatically
# Server is ready!
```

