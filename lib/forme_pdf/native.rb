# frozen_string_literal: true

require "ffi"
module FormePDF
  # Loads only a library supplied by this gem's build or package.
  module Native
    extend FFI::Library

    @load_mutex = Mutex.new

    # Load once and validate the versioned C ABI before use.
    def self.load!
      @load_mutex.synchronize do
        return if @loaded
        extension = FFI::Platform.mac? ? "dylib" : "so"
        path = File.expand_path("native/libforme_pdf_native.#{extension}", __dir__)
        fail FormePDF::LoadError, "Forme native library missing; reinstall forme-ruby for your platform (source installs require Rust/Cargo)" unless File.file?(path)
        ffi_lib path
        attach_function :forme_abi_version, [], :uint32
        fail FormePDF::LoadError, "Incompatible Forme native ABI" unless forme_abi_version == 1
        attach_function :forme_render_html, [:pointer, :size_t, :pointer, :size_t], :pointer, blocking: true
        attach_function :forme_result_status, [:pointer], :int32
        attach_function :forme_result_bytes, [:pointer, :uint32, :pointer], :pointer
        attach_function :forme_result_destroy, [:pointer], :void
        @loaded = true
      end
    rescue ::LoadError => e
      fail FormePDF::LoadError, "Cannot load Forme native library: #{e.message}"
    end

    # Copy a borrowed native buffer before its owning result is destroyed.
    def self.copy(result, field)
      length = FFI::MemoryPointer.new(:size_t)
      pointer = forme_result_bytes(result, field, length)
      size = length.read(:size_t)
      return "".b if size.zero?
      fail FormePDF::RenderError, "Native result has a null buffer" if pointer.null?
      pointer.read_string_length(size).b
    end
  end
end
