# forme-ruby

[![CI](https://github.com/clearstackio/forme-ruby/actions/workflows/ci.yml/badge.svg)](https://github.com/clearstackio/forme-ruby/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Render HTML and print CSS to PDF inside Ruby, using the Rust
[Forme](https://github.com/danmolitor/forme) engine. No browser, Node.js,
WebAssembly or separate rendering service is needed.

This is an independent MIT-licensed binding maintained by
[ClearStack](https://github.com/clearstackio), not an official upstream project.
**[0.1.0 is available on RubyGems](https://rubygems.org/gems/forme-ruby/versions/0.1.0).**

## Getting started

Add to your Gemfile and run `bundle install`:

```ruby
gem "forme-ruby", "~> 0.1.0", require: "forme_pdf"
```

Or install directly:

```sh
gem install forme-ruby -v 0.1.0
```

RubyGems selects a matching native package where available. The same packages
and checksums are available in the [GitHub release](https://github.com/clearstackio/forme-ruby/releases/tag/v0.1.0).

```ruby
require "forme_pdf"

pdf = FormePDF.render_html("<h1>Hello from Ruby</h1>")
File.binwrite("hello.pdf", pdf)
```

Ruby 3.2 or later is required. Native packages target Apple Silicon macOS
15+ and Linux AMD64 glibc 2.28+ and need no compiler. Source installs require
network access to locked upstream dependencies. See [installation](docs/installation.md).

## Native platform targets

| Native gem | Qualification environments |
| --- | --- |
| `arm64-darwin` | Apple Silicon macOS 15 and 26 |
| `x86_64-linux-gnu` | Red Hat UBI 8, 9 and 10; Ubuntu 24.04 and 26.04; Arch Linux rolling |

Version 0.1.0 passed the [full release matrix](https://github.com/clearstackio/forme-ruby/actions/runs/35415089757). Red Hat testing uses official UBI images, not RHEL certification.
Linux ARM64, Windows and Alpine/musl binaries are not provided. See the
[installation guide](docs/installation.md) for Ruby and source-build requirements.

## Using Rails

Authorize and select application data first, then render explicitly:

```ruby
html = render_to_string(template: "invoices/pdf", layout: "pdf", formats: [:html])
send_data FormePDF.render_html(html),
  type: "application/pdf", disposition: "inline", filename: "invoice.pdf"
```

Rails is optional. The [Rails guide](docs/rails.md) also covers the opt-in
`FormePDF::Rails` adapter. The gem installs no middleware or routes.

## Learn more

- [Rendering guide](docs/rendering.md): CSS, fonts, diagnostics and error handling.
- [Development](CONTRIBUTING.md): build, test and contribute.
- [Community guidelines](CODE_OF_CONDUCT.md): participating respectfully.
- [Release guide](docs/releasing.md): package qualification and future publication.
- [Changelog](CHANGELOG.md), [license](LICENSE) and [third-party notices](THIRD_PARTY_LICENSES.txt).

Use trusted HTML and assets. The engine can read local image paths and is not a
sandbox for untrusted documents. See [security](SECURITY.md). Report reproducible
bugs through [GitHub issues](https://github.com/clearstackio/forme-ruby/issues)
with synthetic input, Ruby/platform versions and renderer diagnostics.
