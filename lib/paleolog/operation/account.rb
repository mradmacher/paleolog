# frozen_string_literal: true

module Paleolog
  module Operation
    class Account < BaseOperation
      include Operation::CommonValidations

      CREATE_PARAMS = Params.define.(
        name: Params.required.(Params::NameRules),
      )

      UPDATE_PARAMS = Params.define.(
        id: Params.required.(Params::IdRules),
        name: Params.required.(Params::NameRules),
      )

      def create(raw_params)
        authenticate
          .and_then { parameterize(raw_params, CREATE_PARAMS) }
          .and_then { verify(_1, name_uniqueness(Paleolog::Account)) }
          .and_then { carefully(_1, save_account) }
      end

      def update(raw_params)
        authenticate
          .and_then { parameterize(raw_params, UPDATE_PARAMS) }
          .and_then { authorize(_1, can_manage(Paleolog::Account, :id)) }
          .and_then { verify(_1, name_uniqueness(Paleolog::Account)) }
          .and_then { carefully(_1, save_account) }
      end

      private

      def save_account
        lambda do |params|
          repo.find(
            Paleolog::Account,
            repo.save(Paleolog::Account.new(**params)),
          )
        end
      end
    end
  end
end
