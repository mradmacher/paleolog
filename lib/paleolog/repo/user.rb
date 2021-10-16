# frozen_string_literal: true

module Paleolog
  module Repo
    class User
      def delete_all
        Entity.dataset.delete
      end

      def find_by_login(login)
        Entity.where(login: login).first
      end

      def create(attributes)
        # TODO: move that code to some operation
        password_salt = BCrypt::Engine.generate_salt
        password = BCrypt::Password.create(password_salt + attributes[:password])
        Entity.create(attributes.merge(password: password, password_salt: password_salt))
      end

      class Entity < Sequel::Model(Config.db[:users])
        many_to_many :projects, class: 'Paleolog::Repo::Project::Entity', left_key: :user_id, right_key: :project_id,
                                join_table: :research_participations
      end
    end
  end
end
