# frozen_string_literal: true

require "json"

module Ueki
  class HttpClient
    # for test
    module FakeRequester
      def self.included(descendant)
        descendant.const_set(:FAKE_IO, StringIO.new)
      end

      def get(path, params: nil, headers: {})
        request(:get, path:, params:, headers:)
      end

      def post(path, params: nil, headers: {})
        request(:post, path:, params:, headers:)
      end

      def put(path, params: nil, headers: {})
        request(:put, path:, params:, headers:)
      end

      def patch(path, params: nil, headers: {})
        request(:patch, path:, params:, headers:)
      end

      def delete(path, params: nil, headers: {})
        request(:delete, path:, params:, headers:)
      end

      private

      def request(method, path:, params:, headers:)
        { method:, path:, params:, headers: }.to_json.tap do |str|
          self.class::FAKE_IO.write(str)
        end
      end
    end
  end
end
