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

      def authenticate
        authorizer.authenticated? ? pass(nil) : stop_with(UNAUTHENTICATED)
      end

      def authorize(params, func)
        func.call(params) ? pass(params) : stop_with(UNAUTHORIZED)
      end

      def parameterize(params, rules)
        normalized_params, errors = rules.(params)
        errors.empty? ? pass(normalized_params) : stop_with(errors)
      end

      def verify_name_uniqueness(params, collection, scope: nil)
        if name_taken?(collection, params, scope:)
          stop_with({ name: Operation::TAKEN })
        else
          pass(params)
        end
      end

      def pass(value)
        Resonad.success(value)
      end

      def stop_with(value)
        Resonad.failure(value)
      end

      def carefully(&)
        thrown = true
        result = catch(:stop) do
          yield.tap { thrown = false }
        end
        thrown ? stop_with(result) : pass(result)
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

      def name_taken?(collection, params, scope: nil)
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
