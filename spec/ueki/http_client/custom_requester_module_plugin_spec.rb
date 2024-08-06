# frozen_string_literal: true

require_relative "fake_requester"

RSpec.describe "CustomRequester Moddule Plugin" do
  let!(:dummy_client_class) do
    http_client_module = Ueki::HttpClient.new(endpoint, requester: Ueki::HttpClient::FakeRequester)
    Class.new.include(http_client_module).tap do |klass|
      allow(klass).to receive(:name).and_return("DummyClient")
    end
  end
  let!(:endpoint) { "https://example.com" }

  it "CustomRequester is applied" do
    dummy_client_class.get("/abc", params: { message: "test" })
    expect(dummy_client_class::FAKE_IO.string)
      .to eq '{"method":"get","path":"/abc","params":{"message":"test"},"headers":{}}'
  end
end
