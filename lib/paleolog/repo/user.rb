# frozen_string_literal: true

module Paleolog
  module Repo
    class User
      class << self
        include CommonQueries

        def find_by_login(login)
          result = ds.where(login: login).first
          return nil unless result

          Paleolog::User.new(**result)
        end

        def create(attributes)
          # TODO: move that code to some operation
          password_salt = BCrypt::Engine.generate_salt
          password = BCrypt::Password.create(password_salt + attributes[:password])
          find(ds.insert(attributes.merge(password: password, password_salt: password_salt)))
        end

        def entity_class
          Paleolog::User
        end

        def ds
          Config.db[:users]
        end
      end
    end
  end
end
