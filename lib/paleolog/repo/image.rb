# frozen_string_literal: true

module Paleolog
  module Repo
    class Image
      include CommonQueries

      def all_for_species(species_id)
        ds.where(species_id: species_id).all.map { |result|
          Paleolog::Image.new(**result)
        }
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
