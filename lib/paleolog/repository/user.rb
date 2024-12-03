# frozen_string_literal: true

module Paleolog
  module Repository
    class User < Operation::Base
      CreateParams = Params.define.(
        login: Params.required.(Params::NameRules),
        password: Params.required.(Params::NameRules),
      )

      FindParams = Params.define.(
        id: Params.optional.(Params::IdRules),
        login: Params.optional.(Params::NameRules),
      )

      def find(params)
        parameterize(params, FindParams)
          .and_then { carefully(_1, find_user) }
      end

      def create(params)
        parameterize(params, CreateParams)
          .and_then { carefully(_1, create_user) }
      end

      private

      def find_user
        lambda do |params|
          result = db[:users].where(params).first
          break_with(Operation::NOT_FOUND) unless result

          Paleolog::User.new(**result)
        end
      end

      def create_user
        lambda do |params|
          password_salt = BCrypt::Engine.generate_salt
          password = BCrypt::Password.create(password_salt + params[:password])
          id = db[:users].insert(params.merge(password: password, password_salt: password_salt))

          find_user.(id: id)
        end
      end
    end
  end
end
