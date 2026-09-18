# forme-ruby

Independent native Ruby bindings for [Forme](https://github.com/danmolitor/forme).
Render HTML and print CSS to PDF without a browser, Node.js or WebAssembly.

```ruby
gem "forme-ruby", require: "forme_pdf"
```

```ruby
require "forme_pdf"
pdf = FormePDF.render_html("<h1>Hello</h1>")
File.binwrite("hello.pdf", pdf)
result = FormePDF.render_html_result("<p>Report</p>", css: "@page { size: Letter; }")
result.warnings # unsupported CSS and renderer diagnostics
result.passes
```

Pass local fonts as `fonts: [{family: "Report", data: File.binread("font.ttf"), weight: 400, italic: false}]`.
Use inline styles or the `css:` option, embedded data-URI images and registered fonts.
The supported CSS subset differs from browsers. Review warnings and compare report content.

## Rails

The core has no Rails dependency. Render explicitly:

```ruby
html = render_to_string(template: "invoices/pdf", layout: "pdf")
send_data FormePDF.render_html(html), type: "application/pdf", disposition: "inline"
```

Optionally `require "forme_pdf/rails"` and include `FormePDF::Rails` in a controller.
`render_forme_pdf(template:, layout:, locals: {}, **options)` returns bytes for your `send_data` call.
It registers no middleware, routes or Railtie. Your app owns authorization, asset selection and response headers.

## Installation and builds

Ruby 3.2 or later. Platform packages target macOS ARM64 and Linux AMD64 glibc;
those packages carry their shared library and need no Rust compiler.
Source installs require Rust/Cargo, a linker, make, and access to the pinned Git
source and crates.io dependencies. Install-time compilation may take several minutes.
No compilation or downloads occur during require or render.

```sh
bundle install
bundle exec rake compile
bundle exec rspec
bundle exec rake package[source]
bundle exec rake package[native]
```

Run `FormePDF.verify!` for an explicit startup check. Native load errors derive
from `FormePDF::Error`; rendering failures raise `FormePDF::RenderError`.
Input must be valid UTF-8 (other valid Ruby text encodings are transcoded).
PDF output is ASCII-8BIT. Each render owns independent native result storage.

This is not a sandbox for untrusted HTML. The upstream engine may read local
image paths; render trusted documents only, and apply process limits for large
or hostile inputs. The binding does not fetch remote stylesheets or fonts.

Supported binary OS minimums and release artifacts must pass the clean-install
CI matrix before a release is published. Source fallback does not imply support
for every untested architecture. The gem is independent of EBA and eba_kit.

License: MIT; upstream and bundled dependency notices accompany native packages.
