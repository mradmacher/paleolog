# frozen_string_literal: true

module Paleolog
  module Repository
    class User < Operation::Base
      CREATE_PARAMS = Params.define.(
        login: Params.required.(Params::NameRules),
        password: Params.required.(Params::NameRules),
      )

      FIND_PARAMS = Params.define.(
        id: Params.optional.(Params::IdRules),
        login: Params.optional.(Params::NameRules),
      )

      def find(raw_params)
        parameterize(raw_params, FIND_PARAMS)
          .and_then { |params| carefully { find_user(params) } }
      end

      def create(raw_params)
        parameterize(raw_params, CREATE_PARAMS)
          .and_then { |params| carefully { create_user(params) } }
      end

      private

      def find_user(params)
        result = db[:users].where(params).first
        break_with(Operation::NOT_FOUND) unless result

        Paleolog::User.new(**result)
      end

      def create_user(params)
        password_salt = BCrypt::Engine.generate_salt
        password = BCrypt::Password.create(password_salt + params[:password])
        id = db[:users].insert(params.merge(password: password, password_salt: password_salt))

        find_user(id: id)
      end
    end
  end
end
