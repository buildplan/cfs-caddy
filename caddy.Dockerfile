# Stage 1: Build Caddy with plugins using xcaddy
ARG GO_VERSION=1.25
FROM golang:${GO_VERSION}-alpine AS builder

# 1. Install git (required to fetch plugins)
RUN apk add --no-cache git

# 2. Install xcaddy
RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest

WORKDIR /app

# 3. Build the binary
RUN xcaddy build \
    --output /go/bin/caddy \
    --with github.com/hslatman/caddy-crowdsec-bouncer/appsec \
    --with github.com/hslatman/caddy-crowdsec-bouncer/http \
    --with github.com/hslatman/caddy-crowdsec-bouncer/layer4 \
    --with github.com/caddy-dns/cloudflare \
    --with github.com/WeidiDeng/caddy-cloudflare-ip

# Stage 2: Final Image
FROM caddy:latest

# Copy the binary from the builder stage
COPY --from=builder /go/bin/caddy /usr/bin/caddy

# Metadata
LABEL org.opencontainers.image.title="cfs-caddy" \
      org.opencontainers.image.description="Custom Caddy with CrowdSec, Cloudflare DNS, and Cloudflare IP Source" \
      org.opencontainers.image.source="https://github.com/buildplan/cfs-caddy"