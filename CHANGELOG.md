# Changelog

## 0.1.0 (2026-09-18)

Released on [GitHub](https://github.com/clearstackio/forme-ruby/releases/tag/v0.1.0)
and [RubyGems](https://rubygems.org/gems/forme-ruby/versions/0.1.0)
with identical source and native gems.

### Added

- Native HTML-to-PDF rendering with binary output and preserved warnings/pass counts.
- CSS and local TTF options, typed load/render errors and explicit startup verification.
- Independent native result ownership, cleanup and concurrent rendering.
- Optional Rails template adapter with caller-owned permissions and responses.
- Source and native packaging for macOS ARM64 and Linux AMD64 glibc.
- Ruby CI across 3.2, 3.3, 3.4 and 4.0; clean source/native package installs
  on Ruby 3.3 and distribution qualification jobs.
- Public installation, rendering, Rails, development, security and release guides.

### Hardened

- Preserve result ownership during Ruby thread cancellation and metadata failures.
- Replace rebuilt libraries atomically and retain runtime-user read permissions.
- Reject empty package verification runs and missing third-party license text.

### Native baseline

- Forme HTML 0.24.0 at `f408920e632c59da0651b5b6d32f8c1397477673`.
- Build toolchain: Rust 1.94.0; target minimums macOS 15 and glibc 2.28.
- Release commit `266628a` passed the full hosted platform matrix and CodeQL.
- Published all three packages through trusted publishing; registry downloads
  match the qualified CI and GitHub release artifacts byte-for-byte.

### Release preparation

- Prepare macOS ARM native packages and a glibc 2.28 Linux AMD64 build, with
  qualification jobs for UBI 8/9/10, Ubuntu 24.04/26.04 and Arch Linux.
- Add pinned GitHub Actions, dependency/security checks, contribution templates
  and validated trusted publishing with release attestations.
- Document narrowly scoped native dependency audit exceptions and repository setup.
- Deduplicate and sort license files so notices match across macOS and Linux.
