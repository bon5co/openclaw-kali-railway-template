# openclaw-kali-railway-template

Kali Linux + OpenCLAW gateway, configured for one-click Railway deployment.

## Environment Variables

Set these in the **Railway dashboard** under your service's Variables tab:

### Required

| Variable | Description |
|----------|-------------|
| `OPENCLAW_GATEWAY_AUTH_MODE` | `token` (default) or `password` |
| `OPENCLAW_GATEWAY_TOKEN` | Bearer token for gateway auth (auto-generated if empty) |
| `OPENCLAW_GATEWAY_PASSWORD` | Password for gateway auth (if mode is `password`) |

### Channels (optional)

| Variable | Description |
|----------|-------------|
| `OPENCLAW_TELEGRAM_TOKEN` | Telegram bot token |
| `OPENCLAW_DISCORD_TOKEN` | Discord bot token |
| `OPENCLAW_SLACK_TOKEN` | Slack bot/workspace token |

### Security (optional, secure defaults applied)

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENCLAW_GATEWAY_PORT` | `18789` | Gateway listen port |
| `OPENCLAW_GATEWAY_BIND` | `lan` | Bind scope (`loopback`, `lan`, `tailnet`, `custom`) |
| `OPENCLAW_TOOLS_EXEC_SECURITY` | `deny` | Tool exec policy (`deny`, `ask`) |
| `OPENCLAW_SANDBOX_MODE` | `off` | Agent sandbox (`off`, `all`, `non-main`) |
| `OPENCLAW_DM_POLICY` | `pairing` | DM access policy (`pairing`, `allowlist`, `disabled`) |
| `OPENCLAW_DISABLE_BONJOUR` | `1` | Disable mDNS discovery |

## Deploy to Railway

1. Push this repo to GitHub
2. Create a new project in [Railway](https://railway.com)
3. Connect your GitHub repo
4. Set the required environment variables in the Railway dashboard
5. Deploy — Railway will build the Dockerfile and start the gateway
