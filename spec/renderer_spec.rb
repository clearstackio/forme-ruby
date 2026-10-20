# frozen_string_literal: true

require "forme_pdf"
require "open3"
require "rbconfig"
require "timeout"
require "tmpdir"

RSpec.describe FormePDF do
  it "renders a binary PDF and preserves metadata" do
    result = described_class.render_html_result("<h1>Invoice</h1>")
    expect(result.pdf).to start_with("%PDF-")
    expect(result.pdf).to be_frozen
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
  it "destroys output before delivering an asynchronous interruption" do
    ready = Queue.new
    release = Queue.new
    allow(described_class::Native).to receive(:forme_render_html).and_wrap_original do |original, *args|
      pointer = original.call(*args)
      ready << true
      release.pop
      pointer
    end
    expect(described_class::Native).to receive(:forme_result_destroy).once.and_call_original
    worker = Thread.new { described_class.render_html("<p>Interrupted</p>") }
    ready.pop
    worker.kill
    release << true
    worker.join
  ensure
    release << true if release
    worker&.kill&.join
  end
  it "embeds a caller-supplied font and data URI image" do
    font = File.binread(File.join(__dir__, "fixtures/LiberationSans-Regular.ttf"))
    html = "<p style='font-family:Report'>Café report</p><img width='10' height='10' src='data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='>"
    result = described_class.render_html_result(html, fonts: [{family: "Report", data: font}])
    expect(result.pdf).to include("/FontFile2")
    expect(result.pdf).to include("/Subtype /Image")
    expect(result.warnings).to eq([])
  end

  it "renders deeply nested HTML from a non-main thread" do
    script = <<~RUBY
      require "forme_pdf"
      nested = ->(depth) { "<div>" * depth + "x" + "</div>" * depth }
      pdf = Thread.new { FormePDF.render_html(nested.call(200)) }.value
      abort "no PDF" unless pdf.start_with?("%PDF-")
      begin
        Thread.new { Thread.current.report_on_exception = false; FormePDF.render_html(nested.call(5_000)) }.value
        abort "excess nesting rendered"
      rescue FormePDF::RenderError => e
        abort e.message unless e.message.include?("nesting")
      end
      puts "ok"
    RUBY
    output, errors, status = Timeout.timeout(120) { Open3.capture3(RbConfig.ruby, "-I", File.expand_path("../lib", __dir__), "-e", script) }
    expect(output).to eq("ok\n"), errors
    expect(status).to be_success
  end

  it "rejects invalid font weight and italic values" do
    font = File.binread(File.join(__dir__, "fixtures/LiberationSans-Regular.ttf"))
    [{weight: 2.5}, {weight: 0}, {weight: 1001}, {italic: "yes"}].each do |bad|
      expect { described_class.render_html("hi", fonts: [{family: "Report", data: font, **bad}]) }.to raise_error(ArgumentError)
    end
  end

  it "rejects invalid UTF-8 CSS and font families" do
    font = File.binread(File.join(__dir__, "fixtures/LiberationSans-Regular.ttf"))
    expect { described_class.render_html("hi", css: "\xff".b) }.to raise_error(ArgumentError)
    expect { described_class.render_html("hi", fonts: [{family: "\xff".b, data: font}]) }.to raise_error(ArgumentError)
    expect(described_class.render_html("hi", css: "p { color: red; }".encode("UTF-16LE"))).to start_with("%PDF-")
  end

  describe "local images" do
    let(:png) { "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==".unpack1("m") }

    it "omits file images unless an image root allows them" do
      Dir.mktmpdir do |root|
        File.binwrite(File.join(root, "logo.png"), png)
        html = "<img width='10' height='10' src='#{root}/logo.png'>"
        refused = described_class.render_html_result(html)
        expect(refused.pdf).not_to include("/Subtype /Image")
        expect(refused.warnings.join).to include("image_root")
        allowed = described_class.render_html_result("<img width='10' height='10' src='./logo.png'>", image_root: root)
        expect(allowed.pdf).to include("/Subtype /Image")
        expect(allowed.warnings).to eq([])
      end
    end

    it "refuses files outside the image root and non-regular files" do
      Dir.mktmpdir do |root|
        Dir.mktmpdir do |outside|
          File.binwrite(File.join(outside, "secret.png"), png)
          File.symlink(File.join(outside, "secret.png"), File.join(root, "link.png"))
          ["#{outside}/secret.png", "./link.png", "../#{File.basename(outside)}/secret.png", "/dev/zero"].each do |src|
            result = described_class.render_html_result("<img width='10' height='10' src='#{src}'>", image_root: root)
            expect(result.pdf).not_to include("/Subtype /Image")
            expect(result.warnings.join).to include("Local image omitted")
            expect(result.warnings.join).not_to include(outside)
          end
        end
      end
    end

    it "requires an existing image root directory" do
      expect { described_class.render_html("hi", image_root: 1) }.to raise_error(ArgumentError)
      expect { described_class.render_html("hi", image_root: "/nonexistent/forme") }.to raise_error(ArgumentError)
    end
  end

  it "destroys native result when copying PDF bytes fails" do
    allow(described_class::Native).to receive(:copy).and_raise(IOError, "forced copy error")
    expect(described_class::Native).to receive(:forme_result_destroy).once.and_call_original
    expect { described_class.render_html("<p>Copy cleanup</p>") }.to raise_error(IOError)
  end
end
