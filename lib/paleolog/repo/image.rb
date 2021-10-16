# frozen_string_literal: true

module Paleolog
  module Repo
    class Image
      class Entity < Sequel::Model(Config.db[:images])
        many_to_one :species, class: 'Paleolog::Repo::Species::Entity'
      end
    end
  end
end
