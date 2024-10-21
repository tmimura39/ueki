# frozen_string_literal: true

require "faraday"

module Ueki
  class HttpClient
    # HTTP Request processing is defined.
    # You can also use your own Requester class with the same I/F.
    module DefaultRequester
      UNSPECIFIED = Object.new.freeze
      CONTENT_TYPE_HEADER_KEY = "Content-Type"
      private_constant :UNSPECIFIED, :CONTENT_TYPE_HEADER_KEY

      def get(path, params: nil, headers: {}, request_options: {}, response_body_parser: UNSPECIFIED)
        response_body_parser = default_response_body_parser_if_unspecifiied(response_body_parser)
        request(:get, path:, params:, headers:, request_options:, response_body_parser:)
      end

      def post(path, params: nil, headers: {}, request_options: {}, request_body_converter: UNSPECIFIED, response_body_parser: UNSPECIFIED)
        response_body_parser = default_response_body_parser_if_unspecifiied(response_body_parser)
        request_body_converter = default_request_body_converter_if_unspecified(request_body_converter)
        headers = headers.transform_keys(&:to_s)

        headers[CONTENT_TYPE_HEADER_KEY] ||= "application/json" unless params.nil?
        params = request_body_converter.call(content_type: headers[CONTENT_TYPE_HEADER_KEY], params:)
        request(:post, path:, params:, headers:, request_options:, response_body_parser:)
      end

      def put(path, params: nil, headers: {}, request_options: {}, request_body_converter: UNSPECIFIED, response_body_parser: UNSPECIFIED)
        response_body_parser = default_response_body_parser_if_unspecifiied(response_body_parser)
        request_body_converter = default_request_body_converter_if_unspecified(request_body_converter)
        headers = headers.transform_keys(&:to_s)

        headers[CONTENT_TYPE_HEADER_KEY] ||= "application/json" unless params.nil?
        params = request_body_converter.call(content_type: headers[CONTENT_TYPE_HEADER_KEY], params:)
        request(:put, path:, params:, headers:, request_options:, response_body_parser:)
      end

      def patch(path, params: nil, headers: {}, request_options: {}, request_body_converter: UNSPECIFIED, response_body_parser: UNSPECIFIED)
        response_body_parser = default_response_body_parser_if_unspecifiied(response_body_parser)
        request_body_converter = default_request_body_converter_if_unspecified(request_body_converter)
        headers = headers.transform_keys(&:to_s)

        headers[CONTENT_TYPE_HEADER_KEY] ||= "application/json" unless params.nil?
        params = request_body_converter.call(content_type: headers[CONTENT_TYPE_HEADER_KEY], params:)
        request(:patch, path:, params:, headers:, request_options:, response_body_parser:)
      end

      def delete(path, params: nil, headers: {}, request_options: {}, response_body_parser: UNSPECIFIED)
        response_body_parser = default_response_body_parser_if_unspecifiied(response_body_parser)
        request(:delete, path:, params:, headers:, request_options:, response_body_parser:)
      end

      private

      def default_response_body_parser_if_unspecifiied(response_body_parser)
        if response_body_parser == UNSPECIFIED
          require_relative "json_response_body_parser"
          JsonResponseBodyParser
        else
          response_body_parser
        end
      end

      def default_request_body_converter_if_unspecified(request_body_converter)
        if request_body_converter == UNSPECIFIED
          require_relative "request_body_converter"
          RequestBodyConverter
        else
          request_body_converter
        end
      end

      def request(method, path:, params:, headers:, request_options:, response_body_parser:)
        response = _with_request_error_handling do
          _request(method, path:, params:, headers:, request_options:)
        end
        assert_successful_response(response:, response_body_parser:)

        response_body_parser.nil? ? response.body : response_body_parser.call(response.body)
      end

      def assert_successful_response(response:, response_body_parser:)
        status = _pickup_status(response)
        exception_class = pickup_unsuccessful_response_exception_class(status)
        return if exception_class.nil?

        message, status, body, headers = _extract_from_raw_response(response:, response_body_parser:)
        raise exception_class.new(message, status:, body:, headers:, response:)
      end

      # ===========================================================================================
      # The methods defined below depend on faraday.
      # If you want to customize faraday or use another HTTP library, override the methods.
      # If no customization is required, use the default.

      def _request(method, path:, params:, headers:, request_options:)
        _faraday_connection(request_options).public_send(method, path, params, headers)
      end

      def _faraday_connection(request_options)
        @_faraday_connection ||= {}
        @_faraday_connection[request_options] ||= _initialize_faraday_connection(request_options)
      end

      def _initialize_faraday_connection(request_options)
        Faraday.new(url: self.class::ENDPOINT, headers: _default_headers, request: request_options) do |builder|
          builder.response :logger, (defined?(Rails) ? Rails.logger : nil) do |logger|
            logger.filter(/Authorization:\ (.*)/, "Authorization: [token]")
          end

          builder.adapter :net_http
        end
      end

      def _default_headers
        { user_agent: self.class.name }
      end

      def _pickup_status(response)
        response.status
      end

      def _extract_from_raw_response(response:, response_body_parser:)
        message = response.to_hash.except(:request_headers, :response)
        status = response.status
        body = response_body_parser.call(response.body)
        headers = response.headers
        [message, status, body, headers]
      end

      def _with_request_error_handling
        yield
      rescue Faraday::TimeoutError => e
        raise self.class::TimeoutError, e
      rescue StandardError => e
        raise self.class::UnexpectedError, e
      end
    end
  end
end
