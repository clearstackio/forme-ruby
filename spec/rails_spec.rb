# frozen_string_literal: true

require "forme_pdf/rails"
RSpec.describe FormePDF::Rails do
  it "renders explicitly without changing the caller response" do
    controller = Object.new.extend(described_class)
    expect(controller).to receive(:render_to_string).with(template: "reports/show", layout: "pdf", locals: {title: "Report"}, formats: [:html]).and_return("<h1>Report</h1>")
    expect(controller.render_forme_pdf(template: "reports/show", layout: "pdf", locals: {title: "Report"})).to start_with("%PDF-")
  end
end
