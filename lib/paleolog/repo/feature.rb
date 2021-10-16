# frozen_string_literal: true

module Paleolog
  module Repo
    class Feature
      class Entity < Sequel::Model(Config.db[:features])
        many_to_one :species, class: 'Paleolog::Repo::Species::Entity'
        many_to_one :choice
      end
    end
  end
end
