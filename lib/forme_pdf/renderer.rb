# frozen_string_literal: true

require "json"
require "base64"
module FormePDF
  # One native render call with caller-owned input and independently owned output.
  class Renderer
    # Return PDF bytes, renderer warnings and layout pass count.
    def self.call(html, css: nil, fonts: [])
      fail ArgumentError, "HTML must be a String" unless html.is_a?(String)
      html = html.dup
      html.force_encoding(Encoding::UTF_8) if html.encoding == Encoding::BINARY
      fail ArgumentError, "HTML must be valid UTF-8" unless html.valid_encoding?
      html = html.encode(Encoding::UTF_8)
      fail ArgumentError, "CSS must be a String or nil" unless css.nil? || css.is_a?(String)
      fail ArgumentError, "fonts must be an Array" unless fonts.is_a?(Array)
      options = JSON.generate(css: css, fonts: fonts.map { |font|
        fail ArgumentError, "font must contain family and data" unless font.is_a?(Hash) && font[:family].is_a?(String) && font[:data].is_a?(String)
        fail ArgumentError, "unknown font option" unless (font.keys - %i[family data weight italic]).empty?
        {family: font.fetch(:family), data: Base64.strict_encode64(font.fetch(:data)), weight: font.fetch(:weight, 400), italic: font.fetch(:italic, false)}
      })
      Native.load!
      input = FFI::MemoryPointer.from_string(html)
      opts = FFI::MemoryPointer.from_string(options)
      # Async interruption must not arrive between native allocation and ownership.
      Thread.handle_interrupt(Object => :never) do
        result = Native.forme_render_html(input, html.bytesize, opts, options.bytesize)
        fail RenderError, "Native renderer returned no result" if result.null?
        if Native.forme_result_status(result) != 0
          fail RenderError, Native.copy(result, 2).force_encoding(Encoding::UTF_8)
        end
        pdf = Native.copy(result, 0)
        metadata = JSON.parse(Native.copy(result, 1))
        Result.new(pdf: pdf.freeze, warnings: metadata.fetch("warnings").map(&:freeze).freeze, passes: metadata.fetch("passes"))
      ensure
        Native.forme_result_destroy(result) if result && !result.null?
      end
    end
  end
end
