FROM golang:1.27-alpine AS builder

RUN apk add --no-cache git

RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@v0.4.7

RUN xcaddy build v2.11.7 \
    --with github.com/caddy-dns/cloudflare@v0.2.4 \
    --output /go/bin/caddy

FROM alpine:3.24

RUN apk add --no-cache ca-certificates tzdata libcap

COPY --from=builder /go/bin/caddy /usr/bin/caddy

# Allow the non-root caddy user to bind ports 80/443
RUN setcap 'cap_net_bind_service=+ep' /usr/bin/caddy

RUN addgroup -S caddy && adduser -S -G caddy caddy && \
    mkdir -p /config /data /etc/caddy && \
    chown -R caddy:caddy /config /data /etc/caddy

USER caddy

EXPOSE 80 443 443/udp

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
