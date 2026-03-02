FROM --platform=linux/amd64 ghcr.io/bon5co/kali-railway-template:4c27295d289341587bc0e0bbefd0c54d1a6dae5a

# Install Node.js 22 (required by OpenCLAW) and dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        gnupg \
        git \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install OpenCLAW globally via npm (unattended)
ENV OPENCLAW_NO_PROMPT=1
ENV OPENCLAW_NO_ONBOARD=1
RUN npm install -g openclaw@latest

# Create state directory with correct permissions
RUN mkdir -p /root/.openclaw && chmod 700 /root/.openclaw

# Copy entrypoint and config scripts
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# --- Environment variables for Railway configuration ---
# Gateway
ENV OPENCLAW_GATEWAY_PORT=18789
ENV OPENCLAW_GATEWAY_BIND=lan
ENV OPENCLAW_GATEWAY_AUTH_MODE=token
# Set these in Railway dashboard:
#   OPENCLAW_GATEWAY_PASSWORD  - if auth mode is "password"
#   OPENCLAW_GATEWAY_TOKEN     - if auth mode is "token" (auto-generated if empty)
#
# Channels (set in Railway dashboard):
#   OPENCLAW_TELEGRAM_TOKEN
#   OPENCLAW_DISCORD_TOKEN
#   OPENCLAW_SLACK_TOKEN
#
# Security
ENV OPENCLAW_DISABLE_BONJOUR=1
ENV OPENCLAW_TOOLS_EXEC_SECURITY=deny
ENV OPENCLAW_SANDBOX_MODE=off

EXPOSE ${OPENCLAW_GATEWAY_PORT}

ENTRYPOINT ["/entrypoint.sh"]
