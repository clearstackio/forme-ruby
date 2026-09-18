# frozen_string_literal: true

require "forme_pdf"

RSpec.describe FormePDF do
  it "renders a binary PDF and preserves metadata" do
    result = described_class.render_html_result("<h1>Invoice</h1>")
    expect(result.pdf).to start_with("%PDF-")
    expect(result.pdf.encoding).to eq(Encoding::BINARY)
    expect(result.warnings).to eq([])
    expect(result.passes).to be >= 1
  end

  it "preserves unsupported CSS warnings" do
    result = described_class.render_html_result("<p style='zoom:0.8'>Invoice</p>")
    expect(result.warnings.join).to include("zoom")
  end

  it "rejects invalid UTF-8 and wrong types" do
    expect { described_class.render_html("\xff".b) }.to raise_error(ArgumentError)
    expect { described_class.render_html(nil) }.to raise_error(ArgumentError)
    expect { described_class.render_html("hello", unexpected: true) }.to raise_error(ArgumentError)
  end

  it "accepts caller CSS" do
    pdf = described_class.render_html("<p>Letter</p>", css: "@page { size: Letter; }")
    expect(pdf).to include("612")
  end

  it "renders distinct concurrent results" do
    results = 8.times.map do |i|
      Thread.new { 10.times.map { described_class.render_html("<h1>Unique report #{i}</h1>") }.last }
    end.map(&:value)
    expect(results.uniq.size).to eq(8)
    expect(results.all? { |pdf| pdf.start_with?("%PDF-") }).to be(true)
  end

  it "does not silently accept invalid fonts" do
    expect { described_class.render_html("hello", fonts: [{family: "Broken", data: "not a font"}]) }.to raise_error(FormePDF::RenderError)
  end
  it "destroys native output if Ruby metadata decoding fails" do
    expect(described_class::Native).to receive(:forme_result_destroy).once.and_call_original
    allow(JSON).to receive(:parse).and_raise(JSON::ParserError, "forced failure")
    expect { described_class.render_html("<p>Cleanup</p>") }.to raise_error(JSON::ParserError)
  end

  it "destroys native output on render errors" do
    expect(described_class::Native).to receive(:forme_result_destroy).once.and_call_original
    expect { described_class.render_html("hello", fonts: [{family: "Broken", data: "bad"}]) }.to raise_error(FormePDF::RenderError)
  end

  it "supports valid alternate text encodings" do
    expect(described_class.render_html("café".encode("ISO-8859-1"))).to start_with("%PDF-")
  end

end
