# frozen_string_literal: true

module FormePDF
  class Error < StandardError; end
  class RenderError < Error; end
  class LoadError < Error; end
end
