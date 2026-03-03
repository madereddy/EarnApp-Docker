# EarnApp Docker Container

[![Docker Pulls](https://img.shields.io/docker/pulls/madereddy/earnapp)](https://hub.docker.com/r/madereddy/earnapp)

Unofficial containerized version of BrightData's EarnApp with **Debian slim** base, multi-architecture support, and persistent configuration.

> Use my referral link when creating an EarnApp account: [Sign up here](https://earnapp.com/i/s7bb5Y5Z)

---

## Features

- **Multi-arch support:** `amd64`, `arm64`, `arm/v7`
- **Slim image:** ~45-60MB runtime
- **Persistent configuration:** `/etc/earnapp`
- **No runtime downloads:** EarnApp binary is baked into the image
- **Auto-restart loop:** keeps EarnApp running continuously with exponential backoff
- **Works on Linux and ARM devices** (Raspberry Pi, cloud servers)

---

## How to Get UUID

The UUID must be 32 characters of lowercase letters and numbers, prefixed with `sdk-node-`. You can generate one with:

```bash
echo -n sdk-node- && head -c 1024 /dev/urandom | md5sum | tr -d ' -'
```

*Example output:* `sdk-node-0123456789abcdeffedcba9876543210`

Before registering your device, start the container first with your UUID set, then register using:

```
https://earnapp.com/r/YOUR_UUID
```

*Example:* `https://earnapp.com/r/sdk-node-0123456789abcdeffedcba9876543210`

---

## Running the Container

```bash
docker run -d \
  --name earnapp \
  -e EARNAPP_UUID="YOUR_EARNAPP_UUID" \
  -v /etc/earnapp:/etc/earnapp \
  madereddy/earnapp:latest
```

### Docker Compose

```yaml
services:
  earnapp:
    container_name: earnapp
    image: madereddy/earnapp
    environment:
      - EARNAPP_UUID=<YOUR_EARNAPP_UUID>
    restart: unless-stopped
    volumes:
      - /etc/earnapp:/etc/earnapp
```

> **Note:** `unless-stopped` is recommended over `always` - it prevents the container from auto-starting after a deliberate manual stop (e.g. during maintenance).

---

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `EARNAPP_UUID` | Yes | - | Your EarnApp node UUID (`sdk-node-...`) |
| `DEBUG_MODE` | No | `0` | Set to `1` to drop into a bash shell instead of starting EarnApp. Useful for troubleshooting. |

The container stores the following files in `/etc/earnapp`:

| File | Description |
|------|-------------|
| `uuid` | Your EarnApp UUID |
| `status` | Runtime status used by the healthcheck |

---

## Logs

View logs in real-time:

```bash
docker logs -f earnapp
```

Sample output:

```
Registered
EarnApp is active (making money in the background)
```

---

## Image Tags

| Tag | Description |
|-----|-------------|
| `latest` | Current stable release |
| `1.x.x` | Specific EarnApp version |
| `test` | Development builds - **not for production use** |

---

## Inspecting the Image

The image is built with OCI-standard labels for traceability. You can inspect them with:

```bash
docker inspect madereddy/earnapp --format '{{ json .Config.Labels }}'
```

---

## Notes

- The container fakes `hostnamectl` and `lsb_release` so EarnApp can run in a minimal Debian environment.
- The entrypoint keeps EarnApp running and will automatically retry if it crashes, using exponential backoff up to a maximum of 5 minutes between retries.
- If the container reports unhealthy, check that `/etc/earnapp/status` contains `enabled`. This file is written by EarnApp on successful registration.
