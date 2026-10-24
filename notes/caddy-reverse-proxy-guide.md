# Caddy Reverse Proxy Configuration Guide

Caddy receives client requests and forwards them to an application backend.

```text
Browser → Caddy → Application
          HTTPS   localhost:3000
```

These examples use Caddy v2 Caddyfile syntax. Each configuration is independent. Replace domains, ports, and filesystem paths before use.

## 1. Basic reverse proxy with automatic HTTPS

Expose one application through a public domain.

```caddyfile
app.example.com {
    reverse_proxy localhost:3000
}
```

`https://app.example.com/products` reaches `http://localhost:3000/products`.

Caddy automatically manages the public TLS certificate and redirects HTTP to HTTPS. Point DNS to Caddy and make ports 80 and 443 reachable for a typical deployment.

Reference: [Automatic HTTPS](https://caddyserver.com/docs/automatic-https).

## 2. HTTP-only proxy

Use an HTTP endpoint for local development or an internal service.

```caddyfile
http://localhost:8080 {
    reverse_proxy localhost:3000
}
```

Access the application at `http://localhost:8080`. The explicit `http://` scheme disables automatic HTTPS for this site.

Reference: [HTTPS activation rules](https://caddyserver.com/docs/automatic-https#activation).

## 3. Multiple applications using subdomains

Give each service its own hostname.

```caddyfile
app.example.com {
    reverse_proxy localhost:3000
}

api.example.com {
    reverse_proxy localhost:8000
}

admin.example.com {
    reverse_proxy localhost:9000
}
```

| Public hostname | Backend |
| --- | --- |
| `app.example.com` | Frontend on port 3000 |
| `api.example.com` | API on port 8000 |
| `admin.example.com` | Admin service on port 9000 |

Each application operates from its own root path.

Reference: [Caddyfile patterns](https://caddyserver.com/docs/caddyfile/patterns).

## 4. Path-based routing: preserve the prefix

Use this when the API expects paths beginning with `/api`.

```caddyfile
example.com {
    @api path /api /api/*

    handle @api {
        reverse_proxy localhost:8000
    }

    handle {
        reverse_proxy localhost:3000
    }
}
```

- `/api/users` → backend port 8000 receives `/api/users`.
- `/about` → frontend port 3000 receives `/about`.

The final `handle` is the fallback.

Reference: [Routing patterns](https://caddyserver.com/docs/caddyfile/patterns).

## 5. Path-based routing: remove the prefix

Use `handle_path` when clients call `/api/users`, but the backend expects `/users`.

```caddyfile
example.com {
    redir /api /api/ 308

    handle_path /api/* {
        reverse_proxy localhost:8000
    }

    handle {
        reverse_proxy localhost:3000
    }
}
```

`handle_path` removes the matched `/api` prefix. The redirect handles the bare `/api` path.

Applications that generate absolute URLs, redirects, or cookie paths may also need a public base URL setting to work under a subpath.

Reference: [Subpath routing patterns](https://caddyserver.com/docs/caddyfile/patterns).

## 6. Load balancing with health checks

Distribute requests across multiple application instances.

```caddyfile
app.example.com {
    reverse_proxy localhost:3001 localhost:3002 {
        lb_policy round_robin

        health_uri /health
        health_interval 10s
        health_timeout 2s

        lb_try_duration 5s
    }
}
```

Requests rotate between healthy backends. Each application should return HTTP `200` from `/health`. Caddy checks periodically; `lb_try_duration` enables retries when selecting an available backend.

For primary/backup failover, replace the policy with:

```caddyfile
lb_policy first
```

With health checks enabled, Caddy prefers the first healthy backend in the configured list.

Reference: [Load balancing and health checks](https://caddyserver.com/docs/caddyfile/directives/reverse_proxy#load-balancing).

## 7. HTTPS connection to the backend

Use this when the upstream application also serves HTTPS.

```caddyfile
app.example.com {
    reverse_proxy https://backend.example.net {
        header_up Host backend.example.net
    }
}
```

```text
Browser ──HTTPS──> Caddy ──HTTPS──> Backend
```

The backend must present a certificate trusted by Caddy. The explicit `Host` override also works with older Caddy versions; Caddy 2.11+ sets it automatically for HTTPS upstreams.

Reference: [HTTPS upstreams](https://caddyserver.com/docs/caddyfile/directives/reverse_proxy#https).

## 8. WebSocket application

WebSockets work through a normal reverse proxy configuration.

```caddyfile
chat.example.com {
    reverse_proxy localhost:6001
}
```

Clients connect to `wss://chat.example.com`. Caddy handles the WebSocket upgrade automatically.

Reference: [WebSocket and streaming support](https://caddyserver.com/docs/caddyfile/directives/reverse_proxy#streaming).

## 9. Password-protected application

Add HTTP Basic Authentication before requests reach the backend.

Generate a password hash:

```bash
caddy hash-password
```

Insert the resulting hash into the configuration:

```caddyfile
admin.example.com {
    basic_auth {
        admin REPLACE_WITH_GENERATED_HASH
    }

    reverse_proxy localhost:9000
}
```

Replace `REPLACE_WITH_GENERATED_HASH` with the actual hash. Caddy requires hashed passwords in the configuration.

Reference: [Basic authentication](https://caddyserver.com/docs/caddyfile/directives/basic_auth).

## 10. Static frontend with a proxied API

Serve a built frontend from disk and proxy API requests.

```caddyfile
example.com {
    @api path /api /api/*

    handle @api {
        reverse_proxy localhost:8000
    }

    handle {
        root * /srv/frontend
        try_files {path} /index.html
        file_server
    }
}
```

API requests retain their `/api` prefix. Other requests serve frontend files; missing paths fall back to `index.html`, supporting client-side routing in a single-page application.

Reference: [SPA and API pattern](https://caddyserver.com/docs/caddyfile/patterns).

## Validate and apply the configuration

For a typical Linux installation using `/etc/caddy/Caddyfile`:

```bash
# Format the configuration
sudo caddy fmt --overwrite /etc/caddy/Caddyfile

# Validate before applying
sudo caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile

# Reload a running Caddy instance
sudo caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile
```

Reload requires a running Caddy instance with an accessible admin endpoint.

Reference: [Caddy command-line documentation](https://caddyserver.com/docs/command-line).

## Docker networking note

If Caddy runs in a container, `localhost` refers to that container. For an application in another container on the same Docker network, use its service name:

```caddyfile
app.example.com {
    reverse_proxy frontend:3000
}
```

Ensure both containers join the same network and that the application listens on an interface reachable from Caddy.
