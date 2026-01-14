#!/bin/bash
# Script to copy local tokens to Docker volume for server deployment

echo "🔐 Copying OAuth tokens to Docker volume for server deployment"

# Create a temporary container to access the volume
docker create --name temp-tokens-copy \
  -v calendar-tokens-server:/tokens \
  alpine:latest

# Copy tokens from local machine to the volume
docker cp ~/.config/google-calendar-mcp/tokens.json temp-tokens-copy:/tokens/

# Clean up temp container
docker rm temp-tokens-copy

echo "✅ Tokens copied to 'calendar-tokens-server' volume"
echo "Use this volume when starting your MCP server:"
echo ""
echo "docker run -d \\"
echo "  --name calendar-mcp \\"
echo "  --env GOOGLE_OAUTH_CREDENTIALS_JSON='{...}' \\"
echo "  -v calendar-tokens-server:/home/nodejs/.config/google-calendar-mcp \\"
echo "  ghcr.io/nmirabets/google-calendar-mcp:latest"

