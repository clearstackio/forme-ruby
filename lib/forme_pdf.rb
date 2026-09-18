# frozen_string_literal: true

require_relative "forme_pdf/version"
require_relative "forme_pdf/errors"
require_relative "forme_pdf/result"
require_relative "forme_pdf/native"
require_relative "forme_pdf/renderer"

module FormePDF
  # Render HTML to a binary PDF String.
  def self.render_html(html, **options)
    render_html_result(html, **options).pdf
  end

  # Render HTML and preserve diagnostics.
  def self.render_html_result(html, **options)
    Renderer.call(html, **options)
  end

  # Validate the gem-owned native library eagerly, e.g. at application startup.
  def self.verify!
    Native.load!
    true
  end
end
