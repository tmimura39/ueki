# frozen_string_literal: true

module Ueki
  class HttpClient
    module RequesterShorthand
      def get(path, **args)
        new.get(path, **args)
      end

      def post(path, **args)
        new.post(path, **args)
      end

      def put(path, **args)
        new.put(path, **args)
      end

      def patch(path, **args)
        new.patch(path, **args)
      end

      def delete(path, **args)
        new.delete(path, **args)
      end
    end
    private_constant :RequesterShorthand
  end
end
