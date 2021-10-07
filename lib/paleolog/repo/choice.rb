# frozen_string_literal: true

module Paleolog
  module Repo
    class Choice

      private

      class Entity < Sequel::Model(Config.db[:choices])
        many_to_one :field, class: 'Paleolog::Repo::Field::Entity'
        one_to_many :features
        many_to_many :species, class: 'Paleolog::Repo::Species::Entity', left_key: :choice_id, right_key: :species_id, join_table: :features
      end
    end
  end
end
