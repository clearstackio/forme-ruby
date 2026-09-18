# frozen_string_literal: true

require "forme_pdf"

spec = Gem.loaded_specs.fetch("forme-ruby")
abort "Loaded gem outside the test installation" unless spec.full_gem_path.start_with?(File.join(ENV.fetch("GEM_HOME"), "gems") + File::SEPARATOR)
abort "Expected native Linux package" unless spec.platform.to_s == "x86_64-linux-gnu"
abort "Native package must not build extensions" unless spec.extensions.empty?
FormePDF.verify!
result = FormePDF.render_html_result("<h1>Installed native PDF</h1><table><tr><td>42</td></tr></table>")
abort "Invalid PDF" unless result.pdf.start_with?("%PDF-") && result.pdf.encoding == Encoding::BINARY
library = File.join(spec.full_gem_path, "lib/forme_pdf/native/libforme_pdf_native.so")
abort "Native library is not readable" unless File.stat(library).mode & 0o444 == 0o444
puts "#{RUBY_DESCRIPTION}: #{spec.full_name} rendered #{result.pdf.bytesize} bytes"
