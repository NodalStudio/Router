# Router - Traefik Configuration

This repository contains the Traefik reverse proxy configuration.

## Current Route Mappings

### Port Configuration
- **Port 80**: HTTP traffic (redirected to HTTPS in production)
- **Port 443**: HTTPS traffic
- **Port 8000**: Traefik dashboard (admin:password)

### Service Routes

| Client | Service | Container | Port | Description |
|------------|---------|-----------|------|----------|-------------|
| - | Traefik | `traefik` | 8000 | Traefik dashboard | 
| Alumbra | Deno Fresh | `alumbra-fresh-frontend` | 8001 | Frontend application |
| Alumbra | Strapi | `alumbra-strapi-backend` | 8002 | Strapi admin interface |
| Alumbra | NodeBB | `alumbra-nodebb-forum` | 8003 | Forum platform |

## Network Configuration

All services that are externaly exposed use the external `web` network for Traefik routing. This network must be created before starting the services:

```bash
docker network create web
```

This allows multiple docker-compose stacks to share the same network and communicate with Traefik.

## Adding New Services

To add a new service to the router:

1. Add labels to your service in `docker-compose.yml`:
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.your-service.rule=Host(`localhost`) && PathPrefix(`/your-path`)"
  - "traefik.http.routers.your-service.service=your-service"
  - "traefik.http.routers.your-service.priority=X"
  - "traefik.http.services.your-service.loadbalancer.server.port=YOUR_PORT"
  - "traefik.docker.network=web"
```

2. Connect your service to the `web` network:
```yaml
networks:
  - web
  - app-network  # your internal network if needed
```

3. Update this README with the new route mapping

## Adding New Docker Compose Stacks

To add a completely separate docker-compose stack that also uses Traefik routing:

1. In your new `docker-compose.yml`, reference the external web network:
```yaml
networks:
  web:
    external: true

services:
  your-service:
    # ... your service configuration
    networks:
      - web
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.your-service.rule=Host(`localhost`) && PathPrefix(`/your-path`)"
      # ... other Traefik labels
```

2. The `web` network will already exist and your service will automatically be routed through the same Traefik instance

## SSL/TLS Configuration

### Prerequisites

1. **SSL Certificates Directory**: Each project must have its own `ssl-certs/` directory in the parent folder containing:
   - `cert.crt` - SSL certificate
   - `cert.key` - SSL private key

### Local Setup

1. **Install mkcert for local HTTPS certificates:**
   ```bash
   # macOS
   brew install mkcert
   
   # Windows (with Chocolatey)
   choco install mkcert
   
   # Install local CA in browser trust store
   mkcert -install
   ```

2. **Generate certificates in your project:**
   ```bash
   # From your project root (parent of router/)
   mkdir ssl-certs
   cd ssl-certs
   mkcert localhost "*.localhost" admin.localhost forum.localhost traefik.localhost
   mv localhost+4.pem cert.crt
   mv localhost+4-key.pem cert.key
   ```

### Production Setup

Place your official SSL certificates from your provider in the `ssl-certs/` directory:
- Certificate: `cert.crt` (your domain certificate)
- Private key: `cert.key` (your domain private key)

