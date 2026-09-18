# frozen_string_literal: true

require "open3"
require "rubygems"

library = "lib/forme_pdf/native/libforme_pdf_native.so"
output, status = Open3.capture2("objdump", "-T", library)
abort "Cannot inspect native ABI" unless status.success?
versions = output.scan(/GLIBC_(\d+\.\d+(?:\.\d+)?)/).flatten.map { |v| Gem::Version.new(v) }
abort "No glibc symbols found" if versions.empty?
abort "Native library requires glibc #{versions.max}, above 2.28" if versions.max > Gem::Version.new("2.28")
puts "Maximum required glibc: #{versions.max}"
