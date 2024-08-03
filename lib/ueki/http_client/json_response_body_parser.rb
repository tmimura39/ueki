# frozen_string_literal: true

require "json"

module Ueki
  class HttpClient
    # Simple JSON Parser (default)
    # If it cannot be parsed as JSON, return the value before parsing
    module JsonResponseBodyParser
      module_function

      def call(body)
        return if body.nil? || (body.is_a?(String) && body.empty?)

        JSON.parse(body, symbolize_names: true)
      rescue JSON::ParserError
        body
      end
    end
  end
end
