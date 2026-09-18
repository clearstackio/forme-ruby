# Contributing to Forme Ruby

This guide covers local builds, verification and the boundary of the public gem.
Use synthetic documents and assets that can be redistributed.

## Set up a checkout

Use CRuby 3.2+ and Rust/Cargo 1.94.0, a native linker and make. From the repository:

```bash
bundle install
bundle exec rake compile
bundle exec rspec
cargo test --locked --manifest-path ext/forme_pdf/Cargo.toml
bundle exec standardrb
bundle exec bundler-audit check --update
cargo install cargo-audit --version 0.22.2 --locked
cargo audit --file ext/forme_pdf/Cargo.lock
```

`compile` retains Cargo build output for subsequent development. Source-gem
installation removes its temporary target directory. Build the extension before
running Ruby examples; the loader never compiles during `require`.

## Understand the code

- `lib/forme_pdf.rb` is the public facade; `lib/forme_pdf/` contains loading,
  rendering, immutable results, errors and the explicit Rails adapter.
- `ext/forme_pdf/` owns the Rust C ABI and locked upstream dependencies.
- `spec/` tests Ruby behavior and ownership; Rust tests cover the native boundary.
- `script/` and `.github/workflows/` own notices, installed-package checks and releases.

Keep consumer templates, logos, data access and infrastructure conventions out
of the gem. Preserve per-render ownership, explicit lengths and cleanup in
`ensure`. Do not introduce global result buffers or runtime downloads.

## Test packaging

```bash
ruby script/notices.rb
bundle exec rake 'package[source]'
bundle exec rake 'package[native]'
ruby script/test_packages.rb
```

The installed-package script installs every package in `pkg/` into temporary
GEM_HOME directories, then renders outside the checkout. Keep only packages for
the local platform and source in that directory. Pass package filenames as arguments to test only those artifacts.
It fails if no packages exist.
CI performs clean source/native installation on the supported platforms.

Regenerate and review notices after dependency changes. Notice generation fails
when a dependency has no license text; documented version-specific fallbacks live
under `script/licenses/`. Retain fixture font licenses as well.

## Submit a change

Explain the user-visible behavior, rationale and checks run. Add meaningful
regression coverage for behavior changes. Use StandardRB and update guides and
CHANGELOG when the public API, installation or support matrix changes.
See [release preparation](docs/releasing.md) before packaging a version.

Validate workflow changes with `actionlint`. Linux package reproduction uses
`script/ci/build-linux.sh` inside the pinned UBI 8 image in `ci.yml`; do not run
that container setup script directly on your workstation. Review
[security exceptions](docs/security-exceptions.md) whenever dependencies or the
native API change.
