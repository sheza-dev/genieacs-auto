# genieacs-auto

Production-ready GenieACS automation with wildcard TLS, secure Docker networking, automated repair, and verification scripts.

## What this repository provides

- Secure GenieACS deployment on Docker Compose
- Wildcard TLS termination with Traefik DNS challenge
- MongoDB authentication enabled by default
- Internal-only database network
- Automated scripts to generate secrets, secure the host paths, deploy, repair, verify, and back up the stack
- CI validation for shell scripts and Compose syntax

## Stack

- Traefik for HTTPS and wildcard certificate automation
- GenieACS `drumsergio/genieacs:1.2.16.0`
- MongoDB `8.0`

## Exposed endpoints

All public traffic is terminated on port `443` and routed by subdomain:

- `https://acs.<your-domain>` → GenieACS CWMP (`7547`)
- `https://api.<your-domain>` → GenieACS NBI (`7557`)
- `https://files.<your-domain>` → GenieACS FS (`7567`)
- `https://ui.<your-domain>` → GenieACS UI (`3000`)

Port `80` is only used for HTTP-to-HTTPS redirection. MongoDB is never published publicly.

## Quick start

1. Create the runtime environment file:
   ```bash
   /home/runner/work/genieacs-auto/genieacs-auto/scripts/generate-secrets.sh example.com admin@example.com cloudflare
   ```
2. Edit `/home/runner/work/genieacs-auto/genieacs-auto/.env` if you need custom paths or images.
3. Export your DNS provider credentials required by Traefik/lego before deployment.
4. Point wildcard DNS records for your domain to this host.
5. Deploy the stack:
   ```bash
   /home/runner/work/genieacs-auto/genieacs-auto/scripts/deploy.sh
   ```

## Automation scripts

- `scripts/generate-secrets.sh` — generates `.env` with strong random secrets
- `scripts/secure.sh` — enforces permissions, prepares storage, validates Compose
- `scripts/deploy.sh` — pulls images, starts the stack, then verifies it
- `scripts/repair.sh` — recreates containers, restarts unhealthy services, re-runs verification
- `scripts/confirm.sh` — confirms container health and HTTPS routing
- `scripts/backup.sh` — dumps MongoDB and archives GenieACS data

## Required DNS challenge credentials

Traefik uses the ACME DNS challenge provider set in `.env` as `ACME_DNS_PROVIDER`.
Before running `deploy.sh`, export the variables expected by your provider in the current shell.
Examples:

### Cloudflare

```bash
export CF_DNS_API_TOKEN=replace-me
```

### Route53

```bash
export AWS_ACCESS_KEY_ID=replace-me
export AWS_SECRET_ACCESS_KEY=replace-me
export AWS_REGION=us-east-1
```

## Security defaults

- TLS is enabled on every public GenieACS endpoint
- Wildcard certificates are stored in `data/traefik/acme.json` with `0600` permissions
- MongoDB authentication is enabled and isolated on an internal Docker network
- Containers drop Linux capabilities and enable `no-new-privileges`
- Secrets stay in the ignored `.env` file and are auto-generated with high entropy

## Operational notes

- `scripts/confirm.sh` expects local DNS resolution via `curl --resolve`; it verifies the live reverse proxy on the deployment host.
- Some TR-069 devices do not support HTTPS + SNI correctly. If your fleet has that limitation, front CWMP with a dedicated ACS hostname and test device compatibility before rollout.
- If you want host firewall automation, set `APPLY_UFW=true` in the shell before running `scripts/secure.sh`.

## Validation

Local validation:

```bash
cp .env.example .env
bash -n scripts/*.sh
bash -n scripts/lib/*.sh
docker compose config >/dev/null
```

GitHub Actions runs the same checks on every push and pull request.
