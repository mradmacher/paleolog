# frozen_string_literal: true

module Paleolog
  module Repo
    class Occurrence
      include CommonQueries

      def all_for_sample(counting, sample)
        #Entity.where(counting_id: counting.id, sample_id: sample.id).eager(:species).order { rank.desc }.to_a
        result = ds.where(counting_id: counting.id, sample_id: sample.id).all
        sample = Paleolog::Repo.find(Paleolog::Sample, sample.id)
        species = Paleolog::Repo::Species.new.all_with_ids(result.map { |r| r[:species_id] })
        result.map { |r|
          Paleolog::Occurrence.new(**r) do |occurrence|
            occurrence.species = species.detect { |s| s.id == occurrence.species_id }
            occurrence.sample = sample
          end
        }.sort_by(&:rank).reverse
      end

      def all_for_section(counting, section)
        samples = Paleolog::Repo::Sample.new.all_for_section(section.id)
        sample_ids = samples.map(&:id)
        result = ds.where(counting_id: counting.id, sample_id: sample_ids).all
        species = Paleolog::Repo::Species.new.all_with_ids(result.map { |r| r[:species_id] }.uniq)
        result.map { |r|
          Paleolog::Occurrence.new(**r) do |occurrence|
            occurrence.species = species.detect { |s| s.id == occurrence.species_id }
            occurrence.sample = samples.detect { |s| s.id == occurrence.sample_id }
          end
        }.sort_by(&:rank).reverse
      end

      def available_species_ids(counting, sample, group)
        used_ids = ds.where(counting_id: counting.id, sample_id: sample.id).map { |result| result[:species_id] }
        all = Paleolog::Repo::Species.new.all_for_group(group.id)
        (used_ids.empty? ? all : all.reject { |s| used_ids.include?(s.id) }).sort_by(&:name).map(&:id)
      end

      def rank_exists_within_counting_and_sample?(rank, counting_id, sample_id)
        ds.where(rank: rank, counting_id: counting_id, sample_id: sample_id).limit(1).count > 0
      end

      def species_exists_within_counting_and_sample?(species_id, counting_id, sample_id)
        ds.where(species_id: species_id, counting_id: counting_id, sample_id: sample_id).limit(1).count > 0
      end

      def entity_class
        Paleolog::Occurrence
      end

      def ds
        Config.db[:occurrences]
      end

      def use_timestamps?
        false
      end
    end
  end
end
