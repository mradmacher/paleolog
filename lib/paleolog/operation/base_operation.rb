# frozen_string_literal: true

module Paleolog
  module Operation
    class BaseOperation
      include Operation::Helpers

      attr_reader :repo, :authorizer

      def initialize(repo, authorizer)
        @repo = repo
        @authorizer = authorizer
      end
    end
  end
end
