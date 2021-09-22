# frozen_string_literal: true

module Paleolog
  module Repo
    class User
      private

      class Entity < Sequel::Model(Config.db[:users])
        many_to_many :projects, class: 'Paleolog::Repo::Project::Entity', left_key: :user_id, right_key: :project_id, join_table: :research_participations
      end
    end
  end
end

