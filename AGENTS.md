# Forme Ruby — Agent Guide

This repository is the independent public `forme-ruby` gem. Read
[CONTRIBUTING.md](CONTRIBUTING.md) before editing and [the guides](docs/README.md)
for current contracts. Consumer applications are not dependencies.

## Boundaries

- Install `forme-ruby`; require `forme_pdf`; expose `FormePDF`.
- Keep application records, permissions, report templates, branding and secrets
  out of this repository. Examples and fixtures must be synthetic/licensed.
- Keep Rails optional and explicitly loaded. No automatic middleware or Railtie.
- Preserve opaque per-render ownership, explicit buffer lengths and unconditional
  cleanup. Do not replace results with shared native buffers.
- Build during installation, never during application startup or render.

## Verification

Use the build/test/lint/package commands in CONTRIBUTING. Rebuild Rust after
native changes. Test installed packages outside the checkout. Update Cargo.lock,
NOTICE and generated license text when upstream changes. Do not claim a platform
or Rails version is supported based only on a local smoke test.

## Documentation and delivery

Guides start with purpose and learning outcomes, then prerequisites and examples.
Keep README short; put details in `docs/`. Keep CHANGELOG unreleased until an
actual release. Public docs must work without an internal consumer checkout.

Do not commit, rewrite history, push, tag, dispatch release workflows or publish
unless the user authorizes that action. Never bypass a failed hook. For an
approved history rewrite, keep a local backup ref and compare the final tree.
Local verification does not establish hosted CI success for a rewritten SHA.

Audit exceptions in `.cargo/audit.toml` apply only to the reviewed upstream pin
and HTML API. Re-review their reachability before changing the pin, Cargo
features or exported options; see [the rationale](docs/security-exceptions.md).
Keep the native qualification matrix and installation guide synchronized.
