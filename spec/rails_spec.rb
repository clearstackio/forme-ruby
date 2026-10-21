# frozen_string_literal: true

require "action_controller"
require "tmpdir"
require "forme_pdf/rails"
RSpec.describe FormePDF::Rails do
  around do |example|
    Dir.mktmpdir do |views|
      FileUtils.mkdir_p(File.join(views, "reports"))
      FileUtils.mkdir_p(File.join(views, "layouts"))
      File.write(File.join(views, "reports/show.html.erb"), "<h1><%= title %></h1>")
      File.write(File.join(views, "layouts/pdf.html.erb"), "<html><body><%= yield %></body></html>")
      @views = views
      example.run
    end
  end

  let(:controller_class) do
    views = @views
    Class.new(ActionController::Base) do
      include FormePDF::Rails

      prepend_view_path views

      def self.name = "ReportsController"

      def show
        send_data render_forme_pdf(template: "reports/show", layout: "pdf", locals: {title: "Quarterly report"}),
          type: "application/pdf", disposition: "inline", filename: "report.pdf"
      end
    end
  end

  it "renders a real controller template and layout into a PDF response" do
    controller = controller_class.new
    controller.set_request!(ActionDispatch::TestRequest.create)
    controller.set_response!(ActionDispatch::TestResponse.new)
    controller.process(:show)
    expect(controller.response.media_type).to eq("application/pdf")
    expect(controller.response.body).to start_with("%PDF-")
  end

  it "forwards rendering options to FormePDF" do
    controller = controller_class.new
    controller.set_request!(ActionDispatch::TestRequest.create)
    pdf = controller.send(:render_forme_pdf, template: "reports/show", layout: "pdf", locals: {title: "Letter"}, css: "@page { size: Letter; }")
    expect(pdf).to include("612")
  end

  it "does not expose the helper as a controller action" do
    expect(controller_class.action_methods).to include("show")
    expect(controller_class.action_methods).not_to include("render_forme_pdf")
  end
end
