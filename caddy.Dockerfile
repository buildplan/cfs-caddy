# Stage 1: Build Caddy with plugins using xcaddy
ARG GO_VERSION=1.25
ARG CADDY_VERSION

# 1: Pin the builder to the native hardware ($BUILDPLATFORM)
FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine AS builder

ARG CADDY_VERSION
ARG BOUNCER_VERSION
ARG CF_VERSION

# 2: Docker automatically passes these args
ARG TARGETARCH
ARG TARGETOS

# 1. Install git
RUN apk add --no-cache git

# 2. Install xcaddy
RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest

WORKDIR /app

# 3. Build the binary (Cross-Compilation)
RUN GOOS=${TARGETOS} GOARCH=${TARGETARCH} xcaddy build v${CADDY_VERSION} \
    --output /go/bin/caddy \
    --with github.com/hslatman/caddy-crowdsec-bouncer/appsec@v${BOUNCER_VERSION} \
    --with github.com/hslatman/caddy-crowdsec-bouncer/http@v${BOUNCER_VERSION} \
    --with github.com/hslatman/caddy-crowdsec-bouncer/layer4@v${BOUNCER_VERSION} \
    --with github.com/caddy-dns/cloudflare@v${CF_VERSION} \
    --with github.com/WeidiDeng/caddy-cloudflare-ip

# Stage 2: Final Image
# Use a pinned version of the base image to match the binary
FROM caddy:${CADDY_VERSION}-alpine

# Copy the binary from the builder stage
COPY --from=builder /go/bin/caddy /usr/bin/caddy

# Metadata
LABEL org.opencontainers.image.title="cfs-caddy" \
      org.opencontainers.image.description="Custom Caddy with CrowdSec, Cloudflare DNS, and Cloudflare IP Source" \
      org.opencontainers.image.source="https://github.com/buildplan/cfs-caddy" \
      org.opencontainers.image.version="${CADDY_VERSION}-b${BOUNCER_VERSION}-cf${CF_VERSION}"