# Rendering PDFs

After reading this guide, you will know how to render trusted HTML, register
fonts and inspect diagnostics. Install the gem before running these examples.

## Render HTML

```ruby
require "forme_pdf"

pdf = FormePDF.render_html("<h1>Invoice</h1>", css: "@page { size: Letter; margin: 0.75in; }")
File.binwrite("invoice.pdf", pdf)
```

Input must be a String containing valid text. Valid non-UTF-8 encodings are
transcoded; binary input is interpreted as UTF-8. The result is a frozen binary
ASCII-8BIT String. Always write with `File.binwrite`.

## Style pages and supply assets

Forme supports a subset of HTML and print CSS, not browser layout or JavaScript.
Use dedicated print styles and inspect the resulting pages. Inline CSS or pass
`css:`; embed images as data URIs. The binding does not fetch remote stylesheets,
fonts or images.

Image sources starting with `/`, `./` or `../` are files. They are omitted with a
warning unless you pass `image_root:`, a directory that must contain them:

```ruby
pdf = FormePDF.render_html(
  '<img src="./logo.png" width="120">',
  image_root: Rails.root.join("app/assets/images")
)
```

Relative paths resolve against `image_root`; absolute paths and symlinks must
resolve inside it. Each file must be a regular PNG, JPEG or WebP file of at most
64 MiB. Warnings name the reason, never the path.

Supply TTF font bytes explicitly:

```ruby
pdf = FormePDF.render_html(
  '<p style="font-family: Report">A document</p>',
  fonts: [{family: "Report", data: File.binread("report.ttf"), weight: 400, italic: false}]
)
```

`css:`, `fonts:` and `image_root:` are the supported rendering keywords. Font
entries accept `family`, `data`, `weight` (an Integer from 1 to 1000, default
400) and `italic` (true or false, default false). Unknown or invalid options
raise `ArgumentError`. Register the weights/styles your document needs and check the PDF.

## Inspect diagnostics

```ruby
result = FormePDF.render_html_result("<p>Report</p>")
File.binwrite("report.pdf", result.pdf)
puts result.passes
result.warnings.each { |warning| warn warning }
```

The result and its warning array/strings are frozen. Unsupported CSS can produce
warnings without a failed render. Review warnings using synthetic input; do not
send sensitive document content or diagnostics to public logs.

## Handle errors and concurrency

`FormePDF::LoadError` and `FormePDF::RenderError` inherit `FormePDF::Error`.
Invalid caller arguments, including text that is not valid UTF-8, raise
`ArgumentError`. Documents nested more than 512 elements deep raise
`FormePDF::RenderError` instead of rendering. Avoid
rescuing everything and returning an HTML success response as if it were a PDF.

Each render owns independent native result storage. Ruby copies the bytes and
frees that result even when copying or decoding fails. Native calls release the
Ruby lock and render on a native thread with its own 64 MiB stack, so deep
documents behave the same on Puma, Sidekiq and `Thread.new` threads as on the
main thread. Concurrent callers do not share output buffers. Ruby interruption is
masked during native ownership, so thread cancellation is not a render deadline.
Use process-level resource limits for large or hostile inputs. The API is not a
sandbox and exposes no per-render timeout.
