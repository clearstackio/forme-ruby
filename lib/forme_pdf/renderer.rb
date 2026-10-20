# frozen_string_literal: true

require "json"
require "base64"
module FormePDF
  # One native render call with caller-owned input and independently owned output.
  class Renderer
    # Return PDF bytes, renderer warnings and layout pass count.
    def self.call(html, css: nil, fonts: [], image_root: nil)
      fail ArgumentError, "HTML must be a String" unless html.is_a?(String)
      html = utf8(html, "HTML")
      fail ArgumentError, "CSS must be a String or nil" unless css.nil? || css.is_a?(String)
      fail ArgumentError, "fonts must be an Array" unless fonts.is_a?(Array)
      options = JSON.generate(css: css && utf8(css, "CSS"), fonts: fonts.map { |font| font_option(font) }, image_root: image_root_option(image_root))
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

    # Binary text is read as UTF-8; other valid encodings are transcoded.
    def self.utf8(text, name)
      text = text.dup
      text.force_encoding(Encoding::UTF_8) if text.encoding == Encoding::BINARY
      fail ArgumentError, "#{name} must be valid UTF-8" unless text.valid_encoding?
      text.encode(Encoding::UTF_8)
    end

    def self.font_option(font)
      fail ArgumentError, "font must contain family and data" unless font.is_a?(Hash) && font[:family].is_a?(String) && font[:data].is_a?(String)
      fail ArgumentError, "unknown font option" unless (font.keys - %i[family data weight italic]).empty?
      weight = font.fetch(:weight, 400)
      italic = font.fetch(:italic, false)
      fail ArgumentError, "font weight must be an Integer from 1 to 1000" unless weight.is_a?(Integer) && weight.between?(1, 1000)
      fail ArgumentError, "font italic must be true or false" unless [true, false].include?(italic)
      {family: utf8(font[:family], "font family"), data: Base64.strict_encode64(font[:data]), weight: weight, italic: italic}
    end

    def self.image_root_option(root)
      return if root.nil?
      fail ArgumentError, "image_root must be a String or Pathname" unless root.is_a?(String) || root.respond_to?(:to_path)
      root = File.expand_path(root.respond_to?(:to_path) ? root.to_path : root)
      fail ArgumentError, "image_root must be an existing directory" unless File.directory?(root)
      utf8(root, "image_root")
    end
    private_class_method :utf8, :font_option, :image_root_option
  end
end
