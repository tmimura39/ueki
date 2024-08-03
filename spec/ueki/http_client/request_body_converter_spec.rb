# frozen_string_literal: true

require "ueki/http_client/request_body_converter"

RSpec.describe Ueki::HttpClient::RequestBodyConverter do
  describe ".call" do
    context "when content_type is application/json" do
      let!(:content_type) { "application/json" }
      let!(:params) { { message: "test" } }

      it "JSON string to be returned" do
        expect(described_class.call(content_type:, params:))
          .to eq('{"message":"test"}')
      end
    end

    context "when content_type is application/x-www-form-urlencoded" do
      let!(:content_type) { "application/x-www-form-urlencoded" }
      let!(:params) { { message: "test" } }

      it "URI Encoded string to be returned" do
        expect(described_class.call(content_type:, params:))
          .to eq("message=test")
      end
    end

    context "when content_type is other" do
      let!(:content_type) { "plain/text" }
      let!(:params) { "test" }

      it "not converted String to be returned" do
        expect(described_class.call(content_type:, params:))
          .to eq("test")
      end
    end
  end
end
