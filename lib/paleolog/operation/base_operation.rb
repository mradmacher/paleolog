# frozen_string_literal: true

require 'resonad'

module Paleolog
  module Operation
    class BaseOperation
      attr_reader :repo, :authorizer

      def initialize(repo, authorizer)
        @repo = repo
        @authorizer = authorizer
      end

      protected

      def authenticate
        authorizer.authenticated? ? Resonad.success(nil) : Resonad.failure(UNAUTHENTICATED_RESULT)
      end

      def authorize(params, func)
        func.call(params) ? Resonad.success(params) : Resonad.failure(UNAUTHORIZED_RESULT)
      end

      def parameterize(raw_params, rules)
        params, errors = rules.(raw_params)
        errors.empty? ? Resonad.success(params) : Resonad.failure(errors)
      end

      def verify(params, func)
        errors = func.call(params)
        errors ? Resonad.failure(errors) : Resonad.success(params)
      end

      def merge(params, func)
        Resonad.success(params.merge(func.call(params)))
      end

      def carefully(params, func)
        Resonad.rescuing_from { func.call(params) }
      end

      def can_manage(model, key)
        ->(params) { authorizer.can_manage?(model, params[key]) }
      end

      def can_view(model, key)
        ->(params) { authorizer.can_view?(model, params[key]) }
      end
    end
  end
end
