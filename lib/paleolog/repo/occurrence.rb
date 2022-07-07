# frozen_string_literal: true

module Paleolog
  module Repo
    class Occurrence
      class << self
        include CommonQueries

        # rubocop:disable Metrics/AbcSize
        def find_in_project(id, project_id)
          result = ds.where(Sequel[:occurrences][:id] => id, Sequel[:projects][:id] => project_id)
                     .join(:samples, Sequel[:samples][:id] => :sample_id)
                     .join(:sections, Sequel[:sections][:id] => :section_id)
                     .join(:projects, Sequel[:projects][:id] => :project_id)
                     .select_all(:occurrences)
                     .first
          return nil unless result

          entity_class.new(**result)
        end
        # rubocop:enable Metrics/AbcSize

        # rubocop:disable Metrics/AbcSize
        def all_for_sample(counting, sample)
          # Entity.where(counting_id: counting.id, sample_id: sample.id).eager(:species).order { rank.desc }.to_a
          result = ds.where(counting_id: counting.id, sample_id: sample.id).all
          sample = Paleolog::Repo::Sample.find(sample.id)
          species = Paleolog::Repo::Species.all_with_ids(result.map { |r| r[:species_id] })
          result.map do |r|
            Paleolog::Occurrence.new(**r) do |occurrence|
              occurrence.species = species.detect { |s| s.id == occurrence.species_id }
              occurrence.sample = sample
            end
          end.sort_by(&:rank)
        end
        # rubocop:enable Metrics/AbcSize

        # rubocop:disable Metrics/AbcSize
        def all_for_section(counting, section)
          samples = Paleolog::Repo::Sample.all_for_section(section.id)
          sample_ids = samples.map(&:id)
          result = ds.where(counting_id: counting.id, sample_id: sample_ids).all
          species = Paleolog::Repo::Species.all_with_ids(result.map { |r| r[:species_id] }.uniq)
          result.map do |r|
            Paleolog::Occurrence.new(**r) do |occurrence|
              occurrence.species = species.detect { |s| s.id == occurrence.species_id }
              occurrence.sample = samples.detect { |s| s.id == occurrence.sample_id }
            end
          end.sort_by(&:rank)
        end
        # rubocop:enable Metrics/AbcSize

        def available_species_ids(counting, sample, group)
          used_ids = ds.where(counting_id: counting.id, sample_id: sample.id).map { |result| result[:species_id] }
          all = Paleolog::Repo::Species.all_for_group(group.id)
          (used_ids.empty? ? all : all.reject { |s| used_ids.include?(s.id) }).sort_by(&:name).map(&:id)
        end

        def rank_exists_within_counting_and_sample?(rank, counting_id, sample_id)
          ds.where(rank: rank, counting_id: counting_id, sample_id: sample_id).limit(1).count.positive?
        end

        def species_exists_within_counting_and_sample?(species_id, counting_id, sample_id)
          ds.where(species_id: species_id, counting_id: counting_id, sample_id: sample_id).limit(1).count.positive?
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
end
