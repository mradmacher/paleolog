# frozen_string_literal: true

module Paleolog
  module Operation
    module Helpers
      def authenticate(authorizer)
        lambda { |params|
          authorizer.authenticated? ? [params, {}] : UNAUTHENTICATED_RESULT
        }
      end

      def parameterize(rules)
        lambda { |params|
          params, errors = rules.(params)
          errors.empty? ? [params, {}] : [nil, errors]
        }
      end

      def authorize(func)
        lambda { |params|
          func.call(params) ? [params, {}] : UNAUTHORIZED_RESULT
        }
      end

      def authorize_can_manage(authorizer, model, key)
        lambda { |params|
          authorizer.can_manage?(model, params[key]) ? [params, {}] : UNAUTHORIZED_RESULT
        }
      end

      def verify(func)
        lambda { |params|
          errors = func.call(params)
          errors ? [nil, errors] : [params, {}]
        }
      end

      def merge(func)
        lambda { |params|
          [params.merge(func.call(params)), {}]
        }
      end

      def finalize(func)
        lambda { |params|
          [func.call(params), {}]
        }
      end

      def perform(params, *fns)
        fns.reduce([params, {}]) { |result, fn| result.last.empty? ? fn.call(result.first) : result }
      end
    end
  end
end
