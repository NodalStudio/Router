FROM traefik:v3.0

COPY traefik.yml /etc/traefik/traefik.yml

EXPOSE 80 443 8000