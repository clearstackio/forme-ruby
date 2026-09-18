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
`css:`; embed images as data URIs. The binding does not fetch remote stylesheets
or fonts. Local image paths are possible, so use trusted input only.

Supply TTF font bytes explicitly:

```ruby
pdf = FormePDF.render_html(
  '<p style="font-family: Report">A document</p>',
  fonts: [{family: "Report", data: File.binread("report.ttf"), weight: 400, italic: false}]
)
```

`css:` and `fonts:` are the supported rendering keywords. Font entries accept
`family`, `data`, `weight` (default 400) and `italic` (default false). Unknown
options fail. Register the weights/styles your document needs and check the PDF.

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
Invalid caller arguments can raise `ArgumentError` or encoding errors. Avoid
rescuing everything and returning an HTML success response as if it were a PDF.

Each render owns independent native result storage. Ruby copies the bytes and
frees that result even when copying or decoding fails. Native calls release the
Ruby lock; concurrent callers do not share output buffers. Ruby interruption is
masked during native ownership, so thread cancellation is not a render deadline.
Use process-level resource limits for large or hostile inputs. The API is not a
sandbox and exposes no per-render timeout.
