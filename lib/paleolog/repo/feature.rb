# frozen_string_literal: true

module Paleolog
  module Repo
    class Feature
      include CommonQueries

      def all_for_species(species_id)
        result = ds.where(species_id: species_id).all
        choice_ids = result.map { |f| f[:choice_id] }.uniq
        choices = Paleolog::Repo::Choice.new.all_for(choice_ids)
        result.map { |r|
          Paleolog::Feature.new(**r) { |feature|
            feature.choice = choices.detect { |c| c.id == feature.choice_id }
          }
        }
      end

      def entity_class
        Paleolog::Feature
      end

      def ds
        Config.db[:features]
      end

      def use_timestamps?
        false
      end
    end
  end
end
