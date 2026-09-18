# Rendering PDFs in Rails

After reading this guide, you will know how to render ERB to PDF while retaining
control of permissions, templates and HTTP responses. The core gem does not
require Rails; these examples assume an existing Rails application.

## Render explicitly

Select and authorize records in your application's controller before rendering.
Supply a dedicated HTML template and layout:

```ruby
html = render_to_string(template: "invoices/pdf", layout: "pdf", formats: [:html])
pdf = FormePDF.render_html(html)
send_data pdf, type: "application/pdf", disposition: "inline", filename: "invoice.pdf"
```

Use `attachment` instead of `inline` when the application's download contract
requires it. Application code owns routes, record scopes, filenames, asset
selection and member-data masking. Keep browser print templates separate if
PDF styling needs different behavior.

## Use the optional adapter

```ruby
require "forme_pdf/rails"

class InvoicesController < ApplicationController
  include FormePDF::Rails
end
```

From an already authorized action:

```ruby
pdf = render_forme_pdf(template: "invoices/pdf", layout: "pdf", locals: {invoice: @invoice})
send_data pdf, type: "application/pdf", disposition: "inline", filename: "invoice.pdf"
```

`render_forme_pdf` returns bytes; it does not send a response. It passes
`formats: [:html]` to Rails and forwards rendering options to FormePDF. It does
not prepare assets, select records, install middleware, add routes or register
a Railtie. The host application supplies Rails and controls its lifecycle.

## Verify at startup

Applications that require PDF availability can add this initializer:

```ruby
FormePDF.verify!
```

Load failure then prevents startup instead of silently disabling PDF reports.
Test actual rendering in the deployment image too. The adapter spec uses an
isolated controller double; consumers must test their actual Rails stack and
report routes. No specific Rails version matrix is claimed by this gem.
