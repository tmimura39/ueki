# frozen_string_literal: true

require "ueki/http_client/json_response_body_parser"

RSpec.describe Ueki::HttpClient::JsonResponseBodyParser do
  describe ".call" do
    context "when body is nil" do
      let(:body) { nil }

      it "nil to be returned" do
        expect(described_class.call(body)).to be_nil
      end
    end

    context "when body is empty string" do
      let(:body) { "" }

      it "nil to be returned" do
        expect(described_class.call(body)).to be_nil
      end
    end

    context "when body is JSON string" do
      let(:body) { '{"message":"test"}' }

      it "parsed Hash to be returned" do
        expect(described_class.call(body)).to eq({ message: "test" })
      end
    end

    context "when body is not JSON string" do
      let(:body) { "test" }

      it "unparsed body to be returned" do
        expect(described_class.call(body)).to eq "test"
      end
    end
  end
end
