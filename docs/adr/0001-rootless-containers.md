# ADR 0001: Rootless containers on Gregor

## Context

Membership in the host Docker group grants control of a rootful daemon and is
therefore equivalent to root access. That conflicts with the requirement that
unprivileged development tools and AI assistants cannot read or alter the
root-only archives under `/archive` and `/home/.snapshots`.

Gregor needs one persistent container for Hindsight and Docker Compose-compatible
containers for local development. The former is system-managed; the latter must
remain within the login user's existing filesystem permissions.

## Decision

- Disable rootful Docker and remove the login user from the Docker group.
- Run Hindsight with Podman as the dedicated unprivileged `hindsight` user.
- Provide daemonless, rootless Podman to `jwilger`, including the `docker`
  compatibility command and `podman-compose` provider.
- Keep the system-wide Docker-compatible Podman socket disabled because access
  to that socket would restore a root-equivalent control path.
- Retire the unused self-hosted CI runner instead of preserving its privileged
  Docker-in-Docker design.

## Consequences

Development projects can continue to use `docker compose` or `podman compose`,
but some Docker-specific Compose features may require project-level adjustments.
Rootless containers can bind-mount only paths already accessible to `jwilger`,
so the root-only archives remain outside their authority.

Hindsight keeps its existing image, PostgreSQL database, environment, and
loopback-only network behavior. Its container/image storage moves from Docker's
system store to the `hindsight` user's Podman store; the image will be pulled
again on first activation. Rollback consists of restoring the Docker backend and
service override; no Hindsight data backfill is required because durable state
is held in PostgreSQL outside the container.

Revisit this decision if a required development workload cannot run rootless or
if Hindsight gains a supported native NixOS service that removes the container
boundary entirely.
