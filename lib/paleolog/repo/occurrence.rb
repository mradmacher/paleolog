# frozen_string_literal: true

module Paleolog
  module Repo
    class Occurrence
      def delete_all
        Entity.dataset.delete
      end

      def create(attributes)
        Entity.create(attributes)
      end

      def all_for_sample(counting, sample)
        Entity.where(counting_id: counting.id, sample_id: sample.id).eager(:species).order { rank.desc }.to_a
      end

      def all_for_section(counting, section)
        Entity.where(counting_id: counting.id, sample_id: section.samples.map(&:id)).association_join(:species).order do
          rank.desc
        end.to_a
      end

      class Entity < Sequel::Model(Config.db[:occurrences])
        many_to_one :species, class: 'Paleolog::Repo::Species::Entity', key: :species_id
        many_to_one :sample, class: 'Paleolog::Repo::Sample::Entity', key: :sample_id
        many_to_one :counting, class: 'Paleolog::Repo::Counting::Entity', key: :counting_id
        many_to_many :sections, class: 'Paleolog::Repo::Section::Entity', left_key: :sample_id,
                                right_key: :section_id, join_table: :samples
      end
    end
  end
end
