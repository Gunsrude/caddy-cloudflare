FROM golang:alpine AS builder

RUN apk add --no-cache git && \
    go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest && \
    cd $(go env GOPATH)/src/github.com/caddyserver/xcaddy && \
    xcaddy build --with github.com/caddy-dns/cloudflare --output /go/bin/caddy

FROM alpine:latest

RUN apk add --no-cache ca-certificates tzdata

# Cloudflare DNS-01 credentials (pass at runtime via -e or docker-compose)
ENV CLOUDFLARE_API_TOKEN=""
ENV CLOUDFLARE_DNS_API_TOKEN=""

COPY --from=builder /go/bin/caddy /usr/bin/caddy

RUN addgroup -S caddy && adduser -S -G caddy caddy && \
    mkdir -p /config/caddy /data/caddy /etc/caddy && \
    chown -R caddy:caddy /config /data /etc/caddy

USER caddy

EXPOSE 80 443 443/udp

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
