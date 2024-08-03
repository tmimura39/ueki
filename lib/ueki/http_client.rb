# frozen_string_literal: true

module Ueki
  # Provides a module that automatically defines exception classes and methods required for the HTTP Client Library.
  class HttpClient < Module
    def initialize(endpoint, requester: nil)
      super()
      @endpoint = endpoint

      @requester =
        if requester.nil?
          require_relative "http_client/default_requester"
          DefaultRequester
        else
          requester
        end

      @exception_classes = ExceptionClassBuilder.new.exception_classes
    end

    private

    def included(descendant)
      descendant.const_set(:ENDPOINT, @endpoint)
      @exception_classes.each_pair do |name, object|
        descendant.const_set(name, object)
      end
      descendant.include @requester
      descendant.include UnsuccessfulResponseExceptionClassPicker
      descendant.extend RequesterShorthand
    end
  end
end

require_relative "http_client/exception_class_builder"
require_relative "http_client/requester_shorthand"
require_relative "http_client/unsuccessful_response_exception_class_picker"
