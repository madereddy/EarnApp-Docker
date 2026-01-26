# EarnApp Docker Container

[![Docker Pulls](https://img.shields.io/docker/pulls/madereddy/earnapp)](https://hub.docker.com/r/madereddy/earnapp)

EarnApp container with **Debian slim**, multi-architecture support, and persistent configuration.

Use my referral link when creating an EarnApp account:  
[Sign up here](https://earnapp.com/i/s7bb5Y5Z)

---

## Features

-  **Multi-arch support:** `amd64`, `arm64`, `arm/v7`  
-  **Slim image:** ~50–60MB runtime  
-  **Persistent configuration:** `/etc/earnapp`  
-  **No runtime downloads:** EarnApp binary is baked into the image  
-  **Auto-restart loop:** keeps EarnApp running continuously  
-  **Works on Linux and ARM devices** (Raspberry Pi, cloud servers)

---

## How to Get UUID
1.  The UUID is 32 characters long with lowercase alphabet and numbers. You can either create this by yourself or via this command:
    ```bash
    echo -n sdk-node- && head -c 1024 /dev/urandom | md5sum | tr -d ' -'
    ```

    *Example output* </br>
    *sdk-node-0123456789abcdeffedcba9876543210*

2.  Before registering your device, ensure that you pass the UUID into the container and start it first. Then proceed to register your device using the url:
    ```
    https://earnapp.com/r/UUID
    ```
    *Example url* </br>
    *`https://earnapp.com/r/sdk-node-0123456789abcdeffedcba9876543210`*

## Running the Container
```
docker run -d \
  --name earnapp \
  -e EARNAPP_UUID="YOUR_EARNAPP_UUID" \
  -v /etc/earnapp:/etc/earnapp \
  madereddy/earnapp:latest
```
### Docker Compose Example
```
services:
  earnapp:
    container_name: earnapp
    image: madereddy/earnapp
    environment:
      - EARNAPP_UUID=<YOUR_EARNAPP_UUID>
    restart: always
```
### Environment Variables

The container uses /etc/earnapp to store:
```
    uuid – your EarnApp UUID

    status – runtime status file
```

### Logs

View logs in real-time:
```
docker logs -f earnapp
```
Sample output:
```
✔ Registered
✔ EarnApp is active (making money in the background)
```

### Notes

The container fakes hostnamectl and lsb_release so EarnApp can run in a minimal Debian environment.

The entrypoint keeps EarnApp running and will automatically retry if it crashes.