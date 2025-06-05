# Router - Traefik Configuration

This repository contains the Traefik reverse proxy configuration for the create-profile application stack.

## Current Route Mappings

### Port Configuration
- **Port 80**: HTTP traffic (redirected to HTTPS in production)
- **Port 443**: HTTPS traffic
- **Port 8080**: Traefik dashboard (admin:password)

### Service Routes

| Route Path | Service | Container | Port | Priority | Description |
|------------|---------|-----------|------|----------|-------------|
| `/admin` | Backend (Strapi) | `strapi-backend` | 1337 | 10 | Strapi admin interface |
| `/forum` | Forum (NodeBB) | `nodebb-forum` | 4567 | 5 | Forum application |
| `/` | Frontend | `fresh-frontend` | 8000 | 1 | Main frontend application (catch-all) |

### Priority Explanation
- Higher priority numbers are matched first
- `/admin` (priority 10) matches before `/` (priority 1)
- `/forum` (priority 5) matches before `/` (priority 1)
- `/` (priority 1) acts as a catch-all for all other routes

## Configuration Files

- `traefik.yml`: Main Traefik configuration
- `dynamic/routes.yml`: Dynamic routing configuration
- `docker-compose.yml`: Docker compose for standalone Traefik
- `Dockerfile`: Custom Traefik image with embedded config

## Dashboard Access

The Traefik dashboard is available at:
- URL: `http://traefik.localhost:8080` (when using traefik.localhost as host)
- URL: `http://localhost:8080` (when using localhost)
- Username: `admin`
- Password: `password`

## Network Configuration

All services use the external `web` network for Traefik routing. This network must be created before starting the services:

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

The configuration includes Let's Encrypt integration for automatic SSL certificates in production. Update the email in `traefik.yml` for certificate notifications.

## Usage

To start the router with the main application:
```bash
# Create the shared network first
docker network create web

# Start the services
docker-compose up -d
```

The services will be available at:
- Frontend: http://localhost/
- Strapi Admin: http://localhost/admin
- Forum: http://localhost/forum
- Traefik Dashboard: http://localhost:8080