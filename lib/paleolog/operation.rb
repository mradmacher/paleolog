# frozen_string_literal: true

require 'resonad'

module Paleolog
  module Operation
    UNAUTHORIZED = :unauthorized
    UNAUTHENTICATED = :unauthenticated
    TAKEN = :taken
    NOT_FOUND = :not_found

    def self.unauthorized?(result)
      result == UNAUTHORIZED
    end

    def self.unauthenticated?(result)
      result == UNAUTHENTICATED
    end

    def self.not_found?(result)
      result == NOT_FOUND
    end

    class Base
      attr_reader :db, :authorizer

      def initialize(db, authorizer)
        @db = db
        @authorizer = authorizer
      end

      protected

      # TODO: remove that nil
      def authenticate(params = nil)
        authorizer.authenticated? ? Resonad.success(params) : Resonad.failure(UNAUTHENTICATED)
      end

      def authorize(params, func)
        func.call(params) ? Resonad.success(params) : Resonad.failure(UNAUTHORIZED)
      end

      def parameterize(params, rules)
        normalized_params, errors = rules.(params)
        errors.empty? ? Resonad.success(normalized_params) : Resonad.failure(errors)
      end

      def verify(params, func)
        errors = func.call(params)
        errors ? Resonad.failure(errors) : Resonad.success(params)
      end

      def merge(params, func)
        Resonad.success(params.merge(func.call(params)))
      end

      def carefully(params, func)
        thrown = true
        result = catch(:stop) do
          func.call(params).tap { thrown = false }
        end
        thrown ? Resonad.failure(result) : Resonad.success(result)
      rescue StandardError => e
        Resonad.failure(e)
      end

      def break_with(reason)
        throw :stop, reason
      end

      def can_manage(model, key)
        ->(params) { authorizer.can_manage?(model, params[key]) }
      end

      def can_view(model, key)
        ->(params) { authorizer.can_view?(model, params[key]) }
      end

      def name_exists?(collection, params, scope: nil)
        return false unless params.key?(:name)

        query = collection
        current_id = params[:id]
        name = params[:name]
        if scope
          scope_id = params[scope]
          if scope_id
            query = query.where(scope => scope_id)
          elsif current_id
            query = query.where(scope => collection.where(id: current_id).select(scope))
          end
        end
        query = query.exclude(id: current_id) if current_id

        query.where(Sequel.ilike(:name, name.upcase)).limit(1).count.positive?
      end

      def timestamps_for_create
        { created_at: Time.now, updated_at: Time.now }
      end

      def timestamps_for_update
        { updated_at: Time.now }
      end
    end
  end
end
