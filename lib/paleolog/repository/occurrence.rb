# frozen_string_literal: true

module Paleolog
  module Repository
    class Occurrence < Operation::Base
      FIND_ALL_PARAMS = Params.define do |p|
        {
          counting_id: p::REQUIRED.(p::SLUG_ID),
          sample_id: p::OPTIONAL.(p::SLUG_ID),
          section_id: p::OPTIONAL.(p::SLUG_ID),
        }
      end

      FIND_PARAMS = Params.define do |p|
        {
          id: p::REQUIRED.(p::SLUG_ID),
          project_id: p::OPTIONAL.(p::SLUG_ID),
        }
      end

      CREATE_PARAMS = Params.define do |p|
        {
          counting_id: p::REQUIRED.(p::ID),
          sample_id: p::REQUIRED.(p::ID),
          species_id: p::REQUIRED.(p::ID),
        }
      end

      UPDATE_PARAMS = Params.define do |p|
        {
          id: p::REQUIRED.(p::ID),
          quantity: p::OPTIONAL.(p::BLANK_TO_NIL_OR.(p::ALL_OF.([p::INTEGER, p::GTE.(0)]))),
          status: p::OPTIONAL.(p::ALL_OF.([p::INTEGER, p::INCLUDED_IN.(Paleolog::Occurrence::STATUSES)])),
          uncertain: p::OPTIONAL.(p::BOOL),
        }
      end

      DELETE_PARAMS = Params.define do |p|
        {
          id: p::REQUIRED.(p::ID),
        }
      end

      def find_all(raw_params)
        parameterize(raw_params, FIND_ALL_PARAMS)
          .and_then { |params| carefully { find_all_occurrences(params) } }
      end

      def find(raw_params)
        authenticate
          .and_then { parameterize(raw_params, FIND_PARAMS) }
          .and_then { |params| carefully { find_occurrence(params) } }
      end

      def create(raw_params)
        parameterize(raw_params, CREATE_PARAMS)
          .and_then { verify_species_uniqueness(_1) }
          .and_then { pass(with_default_status(_1)) }
          .and_then { pass(with_next_rank(_1)) }
          .and_then { |params| carefully { create_occurrence(params) } }
      end

      def update(raw_params)
        parameterize(raw_params, UPDATE_PARAMS)
          .and_then { |params| carefully { update_occurrence(params) } }
      end

      def delete(raw_params)
        parameterize(raw_params, DELETE_PARAMS)
          .and_then { |params| carefully { delete_occurrence(params) } }
      end

      private

      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/AbcSize
      def find_all_occurrences(params)
        query = db[:occurrences].where(counting_id: params[:counting_id])
        query = query.where(sample_id: params[:sample_id]) if params[:sample_id]
        if params[:section_id]
          query = query.join(:samples, Sequel[:samples][:id] => :sample_id)
                       .join(:sections, Sequel[:sections][:id] => Sequel[:samples][:section_id])
                       .where(Sequel[:sections][:id] => params[:section_id])
        end
        result = query.select_all(:occurrences)

        groups = db[:groups].all.map do |group_result|
          Paleolog::Group.new(**group_result)
        end
        all_species = db[:species].where(id: result.map { |r| r[:species_id] }).all.map do |species_result|
          Paleolog::Species.new(**species_result) do |species|
            species.group = groups.detect { |group| group.id == species.group_id }
          end
        end
        all_samples = db[:samples].where(id: result.map { |r| r[:sample_id] }).all.map do |sample_result|
          Paleolog::Sample.new(**sample_result)
        end

        result.map do |r|
          Paleolog::Occurrence.new(**r) do |occurrence|
            occurrence.species = all_species.detect { |s| s.id == occurrence.species_id }
            occurrence.sample = all_samples.detect { |s| s.id == occurrence.sample_id }
          end
        end.sort_by(&:rank)
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity

      # rubocop:disable Metrics/AbcSize
      def find_occurrence(params)
        result = if params[:project_id]
                   db[:occurrences]
                    .where(Sequel[:occurrences][:id] => params[:id], Sequel[:projects][:id] => params[:project_id])
                    .join(:samples, Sequel[:samples][:id] => :sample_id)
                    .join(:sections, Sequel[:sections][:id] => :section_id)
                    .join(:projects, Sequel[:projects][:id] => :project_id)
                    .select_all(:occurrences)
                    .first
                 else
                   db[:occurrences].where(id: params[:id]).first
                 end
        break_with(Operation::NOT_FOUND) unless result

        Paleolog::Occurrence.new(**result) do |occurrence|
          species_result = db[:species].where(id: occurrence.species_id).first
          occurrence.species = Paleolog::Species.new(**species_result) do |species|
            species.group = Paleolog::Group.new(**db[:groups].where(id: species.group_id).first)
          end
        end
      end
      # rubocop:enable Metrics/AbcSize

      def create_occurrence(params)
        occurrence_id = db[:occurrences].insert(**params)
        find_occurrence(id: occurrence_id)
      end

      def update_occurrence(params)
        db[:occurrences].where(id: params[:id]).update(**params)
        find_occurrence(id: params[:id])
      end

      def delete_occurrence(params)
        db[:occurrences].where(id: params[:id]).delete
      end

      def verify_species_uniqueness(params)
        exists = db[:occurrences].where(
          species_id: params[:species_id],
          counting_id: params[:counting_id],
          sample_id: params[:sample_id],
        ).limit(1).count.positive?

        exists ? stop_with(species_id: Operation::TAKEN) : pass(params)
      end

      def with_default_status(params)
        params.merge(status: Paleolog::Occurrence::NORMAL)
      end

      def with_next_rank(params)
        max_rank = db[:occurrences]
                   .where(counting_id: params[:counting_id], sample_id: params[:sample_id])
                   .max(:rank)
        params.merge(rank: (max_rank || 0) + 1)
      end

      # def available_species_ids(counting_id, sample_id, group_id)
      #   used_ids = ds.where(counting_id: counting_id, sample_id: sample_id).map { |result| result[:species_id] }
      #   all = Paleolog::Repo::Species.all_for_group(group_id)
      #   (used_ids.empty? ? all : all.reject { |s| used_ids.include?(s.id) }).sort_by(&:name).map(&:id)
      # end
    end
  end
end
