# Installing Forme Ruby

After reading this guide, you will know how installation differs between Git,
source and native packages, and how to check the installed renderer.

## Requirements

CRuby 3.3 or later. Rails is optional.

| Package | Needs |
| --- | --- |
| `arm64-darwin` | macOS 15 or later on Apple Silicon. |
| `x86_64-linux-gnu` | Linux AMD64 with glibc 2.28 or later. |
| `ruby` source gem or Git checkout | Rust/Cargo 1.94.0, a C linker, make and network access to the pinned Git and crates.io dependencies. |

Native gems need no compiler and no system Forme library.

## Install from GitHub

Download the matching native gem and `SHA256SUMS` from the
[0.1.0 release](https://github.com/clearstackio/forme-ruby/releases/tag/v0.1.0).
Check its digest with `shasum -a 256 <filename>` against the checksum file, then
run `gem install ./<filename>`.

## Install from RubyGems

Add to your Gemfile and run `bundle install`:

```ruby
gem "forme-ruby", "~> 0.1.0", require: "forme_pdf"
```

Bundler selects a matching native package where available and otherwise
installs the source gem, which needs the build tools above.

## Verify the installation

```bash
bundle exec ruby -rforme_pdf -e 'FormePDF.verify!; abort "Invalid PDF" unless FormePDF.render_html("<h1>Hello</h1>").start_with?("%PDF-")'
```

`verify!` checks loading and ABI compatibility; the render exercises the engine.
For `FormePDF::LoadError`, check the installed platform and library permissions.
Reinstall the matching gem instead of copying a library from another platform.
