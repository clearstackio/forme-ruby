# frozen_string_literal: true

require "forme_pdf"

module FormePDF
  # Explicitly include this module in an ActionController; no Railtie or middleware.
  module Rails
    # Render a caller-selected Rails template into binary PDF bytes.
    # The controller retains responsibility for authorization and send_data.
    def render_forme_pdf(template:, layout:, locals: {}, **options)
      html = render_to_string(template: template, layout: layout, locals: locals, formats: [:html])
      FormePDF.render_html(html, **options)
    end
  end
end
