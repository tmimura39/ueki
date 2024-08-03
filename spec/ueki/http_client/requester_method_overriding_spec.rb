# frozen_string_literal: true

require "faraday/net_http_persistent"

RSpec.describe "Requester Method Overriding" do
  let!(:dummy_client_class) do
    klass = Class.new.include(Ueki::HttpClient.new(endpoint))
    klass.class_eval do
      def _initialize_faraday_connection(request_options)
        Faraday.new(url: self.class::ENDPOINT, headers: _default_headers, request: request_options) do |builder|
          builder.adapter :net_http_persistent, pool_size: 5 do |http|
            http.idle_timeout = 100
          end
        end
      end
    end
    allow(klass).to receive(:name).and_return("DummyClient")

    klass
  end
  let!(:endpoint) { "http://example.com" }

  it "overridingRequesterMethod is applied" do
    stub = stub_request(:get, "http://example.com/users")
           .to_return(status: 200, body: { users: [{ id: 1, name: "tarou" }] }.to_json)

    dummy_client = dummy_client_class.new
    response = dummy_client.get("/users")
    expect(response).to eq({ users: [{ id: 1, name: "tarou" }] })
    expect(stub).to have_been_requested

    faraday_connection = dummy_client.send(:_faraday_connection, {})
    expect(faraday_connection.adapter).to eq Faraday::Adapter::NetHttpPersistent
  end
end
