# Router - Traefik Configuration

This repository contains the Traefik reverse proxy configuration.

## Current Route Mappings

### Port Configuration
- **Port 80**: HTTP traffic (redirected to HTTPS in production)
- **Port 443**: HTTPS traffic
- **Port 8000**: Traefik dashboard (admin:password)

### Service Routes

| Client     | Service    | Container                | Port | Description            |
|------------|------------|--------------------------|------|------------------------|
| -          | Traefik    | `traefik`                | 8000 | Traefik dashboard      |
| -          | MySQL      | `mysql`                  | 8001 | Shared database        | 
| Alumbra    | Deno Fresh | `alumbra-fresh-frontend` | 8002 | Frontend application   |
| Alumbra    | Strapi     | `alumbra-strapi-backend` | 8003 | Strapi admin interface |

## 🌐 Hybrid Configuration

This router automatically handles:
- **Development**: HTTP-only for `.localhost` domains  
- **Production**: HTTPS with Let's Encrypt for real domains

### Smart Domain Detection
- **`.localhost` domains**: HTTP only, no SSL
- **Real domains**: Automatic HTTPS with Let's Encrypt

### Middleware Configuration
The HTTPS redirect middleware is defined directly in `docker-compose.yml`:
```yaml
- "traefik.http.middlewares.https-redirect.redirectscheme.scheme=https"
- "traefik.http.middlewares.https-redirect.redirectscheme.permanent=true"
```

## 📁 Files Overview

- `docker-compose.yml` - Traefik container with middleware definitions
- `traefik.yml` - Core Traefik configuration with Let's Encrypt
- `acme.json` - Let's Encrypt certificate storage (auto-created)

## 🔗 Network Configuration

Services connect via the external `web` network, allowing multiple docker-compose stacks to share the same Traefik instance.

## 🔧 Adding New Services

To add a new service with hybrid HTTP/HTTPS support:

### 1. Basic Service Labels
```yaml
labels:
  - "traefik.enable=true"
  # HTTP route (always available)
  - "traefik.http.routers.your-service.rule=Host(`${YOUR_HOST}`)"
  - "traefik.http.routers.your-service.entrypoints=web"
  # HTTPS route (only for real domains)
  - "traefik.http.routers.your-service-secure.rule=Host(`${YOUR_HOST}`) && !HostRegexp(`{host:.+\\.localhost}`)"
  - "traefik.http.routers.your-service-secure.entrypoints=websecure"
  - "traefik.http.routers.your-service-secure.tls=true"
  - "traefik.http.routers.your-service-secure.tls.certresolver=letsencrypt"
  # Conditional HTTPS redirect
  - "traefik.http.routers.your-service.middlewares=${HTTPS_REDIRECT_MIDDLEWARE:-}"
  - "traefik.http.services.your-service.loadbalancer.server.port=YOUR_PORT"
  - "traefik.docker.network=web"
```

### 2. Network Connection
```yaml
networks:
  - web
  - your-internal-network  # if needed
```

### 3. Environment Variables
Add to your `.env` file:
```bash
YOUR_HOST=your-service.localhost  # dev
# YOUR_HOST=your-service.yourdomain.com  # prod
```

## 🚀 Adding New Projects

For completely separate projects using this router:

1. **Reference the external network:**
```yaml
networks:
  web:
    external: true

services:
  your-service:
    # ... service config
    networks:
      - web
    labels:
      # ... use the hybrid labels pattern above
```

2. **Set the HTTPS_REDIRECT_MIDDLEWARE environment variable:**
```bash
# Development
HTTPS_REDIRECT_MIDDLEWARE=

# Production  
HTTPS_REDIRECT_MIDDLEWARE=https-redirect@docker
```

## 🛠️ Troubleshooting

### Development Issues
- Ensure `HTTPS_REDIRECT_MIDDLEWARE` is empty for localhost
- Use HTTP URLs only: `http://service.localhost`
- Check: `docker logs traefik`

### Production Issues
- Verify domain DNS points to your server
- Ensure port 80/443 are open to internet
- Monitor Let's Encrypt: `docker logs traefik | grep acme`
- Check `TRAEFIK_SSL_EMAIL` is set correctly

### Common Commands
```bash
# Recreate containers (clears cached labels)
docker-compose down && docker-compose up -d

# View Traefik logs
docker logs traefik

# Check certificate permissions
ls -la acme.json  # should be 600
```

