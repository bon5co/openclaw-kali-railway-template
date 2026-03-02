#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${OPENCLAW_STATE_DIR:-/root/.openclaw}"
CONFIG_FILE="${STATE_DIR}/openclaw.json"

mkdir -p "${STATE_DIR}"
chmod 700 "${STATE_DIR}"

# ── Generate gateway token if auth mode is "token" and none provided ──
if [ "${OPENCLAW_GATEWAY_AUTH_MODE:-token}" = "token" ] && [ -z "${OPENCLAW_GATEWAY_TOKEN:-}" ]; then
    OPENCLAW_GATEWAY_TOKEN="$(openclaw doctor --generate-gateway-token 2>/dev/null || openssl rand -hex 32)"
    export OPENCLAW_GATEWAY_TOKEN
    echo "================================================"
    echo " Auto-generated gateway token (save this!):"
    echo " ${OPENCLAW_GATEWAY_TOKEN}"
    echo "================================================"
fi

# ── Build openclaw.json from environment variables ──
build_config() {
    local gw_port="${OPENCLAW_GATEWAY_PORT:-18789}"
    local gw_bind="${OPENCLAW_GATEWAY_BIND:-lan}"
    local gw_auth_mode="${OPENCLAW_GATEWAY_AUTH_MODE:-token}"
    local gw_mode="${OPENCLAW_GATEWAY_MODE:-local}"
    local allowed_origins="${OPENCLAW_ALLOWED_ORIGINS:-*}"

    python3 -c "
import json, os

c = {}

# Gateway
c['gateway'] = {
    'mode': '${gw_mode}',
    'port': int('${gw_port}'),
    'bind': '${gw_bind}',
    'auth': {
        'mode': '${gw_auth_mode}',
        'rateLimit': {
            'maxAttempts': 10,
            'windowMs': 60000,
            'lockoutMs': 300000
        }
    },
    'controlUi': {
        'dangerouslyAllowHostHeaderOriginFallback': True
    }
}

# Auth credentials
if '${gw_auth_mode}' == 'token':
    token = os.environ.get('OPENCLAW_GATEWAY_TOKEN', '')
    if token:
        c['gateway']['auth']['token'] = token
if '${gw_auth_mode}' == 'password':
    pw = os.environ.get('OPENCLAW_GATEWAY_PASSWORD', '')
    if pw:
        c['gateway']['auth']['password'] = pw

# Allowed origins (if user set a specific value)
origins = '${allowed_origins}'
if origins and origins != '*':
    c['gateway']['controlUi'] = {'allowedOrigins': [o.strip() for o in origins.split(',')]}

# Security: tool execution policy
c['tools'] = {
    'exec': {
        'security': '${OPENCLAW_TOOLS_EXEC_SECURITY:-deny}'
    },
    'deny': ['gateway', 'cron', 'sessions_spawn', 'sessions_send']
}

# Sandbox
c['agents'] = {
    'defaults': {
        'sandbox': {
            'mode': '${OPENCLAW_SANDBOX_MODE:-off}'
        }
    }
}

# Logging: redact sensitive fields
c['logging'] = {
    'redactSensitive': 'tools',
    'redactPatterns': ['password.*', 'api[_-]?key.*', 'token.*', 'secret.*']
}

# Channels
channels = {}
telegram_token = os.environ.get('OPENCLAW_TELEGRAM_TOKEN', '')
if telegram_token:
    channels['telegram'] = {'token': telegram_token}
discord_token = os.environ.get('OPENCLAW_DISCORD_TOKEN', '')
if discord_token:
    channels['discord'] = {'accounts': {'default': {'token': discord_token}}}
slack_token = os.environ.get('OPENCLAW_SLACK_TOKEN', '')
if slack_token:
    channels['slack'] = {'tokens': [slack_token]}

dm_policy = '${OPENCLAW_DM_POLICY:-pairing}'
for ch in channels:
    channels[ch]['dmPolicy'] = dm_policy
if channels:
    c['channels'] = channels

# Browser SSRF hardening
c['browser'] = {
    'ssrfPolicy': {
        'dangerouslyAllowPrivateNetwork': False
    }
}

with open('${CONFIG_FILE}', 'w') as f:
    json.dump(c, f, indent=2)
" 2>&1

    chmod 600 "${CONFIG_FILE}"
    echo "[entrypoint] Configuration written to ${CONFIG_FILE}"
}

build_config

# ── Run security audit (informational) ──
openclaw security audit 2>&1 || true

# ── Print config summary (redacted) ──
echo "[entrypoint] Gateway mode:      ${OPENCLAW_GATEWAY_MODE:-local}"
echo "[entrypoint] Gateway auth mode: ${OPENCLAW_GATEWAY_AUTH_MODE:-token}"
echo "[entrypoint] Gateway bind:      ${OPENCLAW_GATEWAY_BIND:-lan}"
echo "[entrypoint] Gateway port:      ${OPENCLAW_GATEWAY_PORT:-18789}"
echo "[entrypoint] Exec security:     ${OPENCLAW_TOOLS_EXEC_SECURITY:-deny}"
echo "[entrypoint] Sandbox mode:      ${OPENCLAW_SANDBOX_MODE:-off}"

# ── Start the gateway ──
echo "[entrypoint] Starting OpenCLAW gateway..."
exec openclaw gateway --port "${OPENCLAW_GATEWAY_PORT:-18789}"
