# frozen_string_literal: true

module Paleolog
  module Operation
    module Helpers
      def authenticate(authorizer)
        lambda { |params|
          authorizer.authenticated? ? Success.new(params) : Failure.new(UNAUTHENTICATED_RESULT)
        }
      end

      def parameterize(rules)
        lambda { |params|
          params, errors = rules.(params)
          errors.empty? ? Success.new(params) : Failure.new(errors)
        }
      end

      def authorize(func)
        lambda { |params|
          func.call(params) ? Success.new(params) : Failure.new(UNAUTHORIZED_RESULT)
        }
      end

      def authorize_can_manage(authorizer, model, key)
        lambda { |params|
          authorizer.can_manage?(model, params[key]) ? Success.new(params) : Failure.new(UNAUTHORIZED_RESULT)
        }
      end

      def authorize_can_view(authorizer, model, key)
        lambda { |params|
          authorizer.can_view?(model, params[key]) ? Success.new(params) : Failure.new(UNAUTHORIZED_RESULT)
        }
      end

      def verify(func)
        lambda { |params|
          errors = func.call(params)
          errors ? Failure.new(errors) : Success.new(params)
        }
      end

      def merge(func)
        lambda { |params|
          Success.new(params.merge(func.call(params)))
        }
      end

      def finalize(func)
        ->(params) { Success.new(func.call(params)) }
      end

      def reduce(params, *fns)
        fns.reduce(Success.new(params)) { |result, fn| result.success? ? fn.call(result.value) : result }
      end
    end
  end
end
