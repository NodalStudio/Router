FROM traefik:v3.0

COPY traefik.yml /etc/traefik/traefik.yml
COPY dynamic /etc/traefik/dynamic

EXPOSE 80 443 8000