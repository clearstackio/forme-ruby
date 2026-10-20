# Preparing and Releasing Forme Ruby

After reading this guide, you will know how to qualify source/native artifacts
and which steps publish externally. **Current status: 0.1.0 is published on GitHub and RubyGems.**
Local preparation does not authorize a push, tag or RubyGems publication.

## Prepare locally

1. Review README, guides, AGENTS, CHANGELOG, gemspec metadata, LICENSE, NOTICE
   and generated third-party notices. Keep public examples free of private data.
2. Run the contributor checks and package-install checks. Inspect package files:
   source gems contain the locked Rust sources/build hook; native gems contain
   their library and no build hook. Confirm guides and all notices are included.
3. Keep `lib/forme_pdf/version.rb` and CHANGELOG aligned. Do not date an unreleased
   entry as if it were published. Review the tested Forme revision and platform
   minimums whenever native dependencies change.
4. If history is explicitly squashed, record old/new refs and keep a backup.
   Previously successful CI does not qualify the new commit. Consumers must not
   lock to an unpublished SHA. Do not change remote history during local preparation.

## Qualify the release commit

After a separately authorized GitHub push, require successful `ci.yml` for that
exact `main` commit, including every package installation job. Review the three
intended artifacts: `ruby`, `arm64-darwin` and `x86_64-linux-gnu`. The
[installation requirements](installation.md) must match what CI qualifies.

The initial history consolidation is complete. Branch `archive/pre-0.1.0-squash`
preserves the earlier history and existing consumer pin. Future releases should
use normal commits without rewriting published history.

Review [GitHub repository setup](github-setup.md) before enabling releases.

## Configure trusted publishing

Under the `ajaya` RubyGems account, configure a pending publisher for the new gem:

| Field | Value |
| --- | --- |
| Gem | `forme-ruby` |
| GitHub owner | `clearstackio` |
| Repository | `forme-ruby` |
| Workflow | `release.yml` |
| Environment | `rubygems` |

Use the matching GitHub environment and review its protections. A pending
publisher becomes associated with the gem after its first successful upload.
See the [official RubyGems trusted publishing guide](https://guides.rubygems.org/trusted-publishing/)
for setup. No long-lived RubyGems API key is required by this workflow.

## Publish only with explicit authorization

Pushing a `v*` tag publishes. `release.yml` runs on the tag and:

1. checks the tag equals `v` plus `FormePDF::VERSION`;
2. finds the successful `ci.yml` run on `main` for the tagged commit and
   downloads its three packages, rebuilding nothing;
3. validates names, versions, platforms, license files and build hooks;
4. records a GitHub build-provenance attestation for those packages;
5. creates the GitHub release with the packages and `SHA256SUMS`, or, when the
   release already exists, requires its packages to match byte-for-byte;
6. signs each package with Sigstore and pushes it to RubyGems through trusted
   publishing with that attestation, then waits until RubyGems serves it.

Tag only a `main` commit whose CI has passed, after the CHANGELOG entry is dated:

```bash
git tag -a vX.Y.Z -m "vX.Y.Z" <main-commit>
git push origin vX.Y.Z
```

Treat the tag push as publication, not a dry run. Afterward, verify all three
platforms and their attestations on RubyGems and install from RubyGems in a clean
environment. Partial publication cannot be overwritten: inspect which platforms
succeeded before deciding how to recover. Update consumer Gemfiles only after
the version is available and qualified.

## Release evidence

[GitHub release 0.1.0](https://github.com/clearstackio/forme-ruby/releases/tag/v0.1.0)
contains the source gem, both native gems and SHA-256 checksums from
[CI run 35415089757](https://github.com/clearstackio/forme-ruby/actions/runs/35415089757).
Every job passed on commit `266628a20a0a52bad222c8f8e6d2277b08122896`, including
every package installation job. CodeQL also
passed. Packages were downloaded and validated before release; the macOS native
gem was additionally installed and rendered locally outside the checkout.

The GitHub `rubygems` environment exists and allows deployment from `main`.
[Registry publication run 35415885728](https://github.com/clearstackio/forme-ruby/actions/runs/35415885728)
succeeded through trusted publishing for all three platforms. Downloads from
RubyGems matched the CI and GitHub release artifacts byte-for-byte. A fresh
macOS ARM registry installation loaded the native library and rendered a PDF.

The publisher is configured; do not recreate it for subsequent versions.
Version 0.1.0 is already published and must not be pushed again. Use a new
version for future releases and qualify its packages before publication.
