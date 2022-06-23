# frozen_string_literal: true

module Paleolog
  module Repo
    class Image
      class << self
        include CommonQueries

        def all_for_species(species_id)
          ds.where(species_id: species_id).all.map do |result|
            Paleolog::Image.new(**result)
          end
        end

        def ds
          Config.db[:images]
        end

        def entity_class
          Paleolog::Image
        end
      end
    end
  end
end
