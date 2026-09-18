# frozen_string_literal: true

require "forme_pdf"

pdf = FormePDF.render_html("<h1>Hello from Ruby</h1>", css: "@page { size: Letter; }")
File.binwrite(ARGV.fetch(0, "hello.pdf"), pdf)
