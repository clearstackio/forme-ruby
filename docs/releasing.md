# Preparing and Releasing Forme Ruby

After reading this guide, you will know how to qualify source/native artifacts
and which steps publish externally. **Current status: 0.1.0 is unreleased.**
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

## Qualify the release commit later

After a separately authorized GitHub push, require successful `ci.yml` for that
exact `main` commit. CI tests CRuby 3.2, 3.3, 3.4 and 4.0 on Ubuntu 24.04 and
macOS 15, builds source/native packages and clean-installs them. The same Linux
artifact renders on UBI 8/9/10, Ubuntu 24.04/26.04 and Arch rolling; the macOS
artifact renders on macOS 15/26. See [installation](installation.md). Review the three intended artifacts: `ruby`,
`arm64-darwin`, and `x86_64-linux-gnu`. No Windows or musl binary is claimed.

The repository already has published history. Replacing it after a local root
squash would be a remote history rewrite, requiring separate authorization and
coordination with consumers. Keep the existing reachable consumer pin until then.

Review [GitHub repository setup](github-setup.md) before enabling releases.

## Configure trusted publishing later

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

The manual `release.yml` workflow takes a successful CI run ID and verifies its
commit, branch and workflow path against the release invocation. It downloads
those tested artifacts and publishes them; it does not rebuild them at release
time. Package validation requires exactly the three intended platforms and
matching names/versions. A provenance attestation records the release workflow
that promotes those artifacts; it does not replace the linked CI build evidence.
Treat dispatching it as publication, not a dry run.

Before dispatch, confirm the version is available, the package inventory is
correct and all three tested artifacts belong to the intended commit. Afterward,
verify all platforms on RubyGems, install from RubyGems in clean environments and
record the release date/tag. Partial publication cannot be overwritten: inspect
which platforms succeeded before deciding how to recover. Update consumer
Gemfiles only after the version is available and qualified.

## Evidence and remaining gates

The earlier `b6d287c` commit passed hosted Linux/macOS CI, including AlmaLinux 10.
That is historical evidence, not approval of a new local squashed SHA. Hosted CI,
trusted-publisher configuration and actual publication remain pending for the
prepared release. No release workflow is run by local package tasks.

Local preparation on 2026-09-18 verified macOS source/native installations and
native Linux rendering in UBI 8/9, Ubuntu 24.04/26.04 and Arch. The UBI 8 build
passed the glibc 2.28 symbol check. Arch's local QEMU run needed pacman's sandbox
disabled; the committed hosted job uses its normal sandbox. UBI 10 could not
start under the local emulator because it requires an x86-64-v3 CPU. Its hosted
x86 check remains mandatory. These local results do not qualify the complete
hosted matrix or authorize publication.
