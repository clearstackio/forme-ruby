# Changelog

## 0.2.0 (2026-10-20)

### Breaking

- File image sources (`/`, `./`, `../`) are omitted with a warning unless the new
  `image_root:` option names a directory containing them. Allowed files are
  inlined after checking they are regular files of at most 64 MiB.
- Font `weight` must be an Integer from 1 to 1000 and `italic` true or false;
  invalid values and non-UTF-8 `css:` or font families raise `ArgumentError`.
- `FormePDF::Rails#render_forme_pdf` is private, so Rails does not expose it as
  a controller action. Call it from your own actions as before.

### Fixed

- Rendering deeply nested HTML on a non-main Ruby thread no longer overflows the
  thread's stack and hangs the process. Renders run on a native thread with a
  64 MiB stack, and documents nested deeper than 512 elements raise
  `FormePDF::RenderError`.
- Failed source builds show Cargo's diagnostics instead of only
  "Forme native build failed".

### Changed

- Require Ruby 3.3 or later. The Ubuntu 24.04 package job installs a pinned
  Ruby 3.3 build in its clean container.
- State only platform requirements in the README and installation guide.
- Update the native engine to Forme HTML 0.28.0 at
  `b97dc101b705ea5d7fea6fb1b20fabfb5bd2d63d`; running headers and footers
  no longer inherit `<body>` color and font.
- Allow the `json` 3.x runtime dependency.
- Refresh locked Rust and development dependencies and regenerate third-party notices.
- Publish on a `v*` tag push instead of a manual dispatch. The release promotes
  the tagged commit's CI packages unchanged, attaches them with `SHA256SUMS` to
  the GitHub release, and pushes each to RubyGems with a Sigstore attestation.
- Re-review native audit exceptions against the new engine revision.
- CI installs the source gem on macOS as well as Linux, verifies the rustup
  installer checksum and pins the Ubuntu test images by digest.

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
