# Installing Forme Ruby

After reading this guide, you will know how installation differs between Git,
source and native packages, and how to check the installed renderer.

## Requirements

Use CRuby 3.2 or later. CI covers Ruby 3.2, 3.3, 3.4 and 4.0 on Linux AMD64 and
macOS ARM64. The core has no Rails dependency. JRuby, Windows, musl and other
architectures are not qualified release targets.

| Package | Requirement |
| --- | --- |
| Git checkout or `ruby` source gem | Rust/Cargo 1.94.0 (qualified toolchain), linker, make, network access to pinned Git and crates.io dependencies. |
| `arm64-darwin` | Apple Silicon, macOS 15 or later. |
| `x86_64-linux-gnu` | AMD64 Linux, glibc 2.28 or later. |

## Native qualification

The Linux library is built inside pinned Red Hat UBI 8 with a baseline x86-64
CPU target. CI rejects symbols requiring glibc newer than 2.28. The same gem
is installed and renders a PDF in UBI 8, 9 and 10, Ubuntu 24.04 and 26.04,
and current Arch Linux, without Rust installed. UBI testing exercises the
RHEL userspace baseline; it is not a certification of every RHEL deployment.
Use a Ruby 3.2+ installation even when a distribution defaults to older Ruby.

The macOS gem is built on Apple Silicon macOS 15 with a 15.0 deployment target
and installed on macOS 15 and 26. Both native artifacts are also installed
across CRuby 3.2, 3.3, 3.4 and 4.0. The [0.1.0 release run](https://github.com/clearstackio/forme-ruby/actions/runs/35415089757)
passed every qualification job. These tests establish installation/rendering compatibility, not
identical pagination for every font and document.

## Install from GitHub

Download the matching native gem and `SHA256SUMS` from the
[0.1.0 release](https://github.com/clearstackio/forme-ruby/releases/tag/v0.1.0).
Check its digest with `shasum -a 256 <filename>` against the checksum file, then
run `gem install ./<filename>`.

Version 0.1.0 is not yet published to RubyGems. For Bundler, add the Git dependency shown in
[README](../README.md) and run `bundle install`. Commit `Gemfile.lock` so builds
use a reviewed revision. Compilation happens during installation; no compiler
or dependency download runs during `require` or rendering.

## Install from RubyGems after registry publication

After publication is confirmed, use:

```ruby
gem "forme-ruby", "~> 0.1.0", require: "forme_pdf"
```

Bundler selects a matching native package where available. A source fallback
requires the build tools above; it is not a promise of support for every platform.
Native packages load their own shared library without a system Forme install.

## Verify the installation

```bash
bundle exec ruby -rforme_pdf -e 'FormePDF.verify!; abort "Invalid PDF" unless FormePDF.render_html("<h1>Hello</h1>").start_with?("%PDF-")'
```

`verify!` checks loading and ABI compatibility; the render exercises the engine.
For `FormePDF::LoadError`, check the installed platform and library permissions.
Reinstall the matching gem instead of copying a library from another platform.
