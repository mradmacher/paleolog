# frozen_string_literal: true

module Paleolog
  module Repository
    class Occurrence < Operation::Base
      FIND_ALL_PARAMS = Params.define.(
        counting_id: Params.required.(Params::SoftIdRules),
        sample_id: Params.optional.(Params::SoftIdRules),
        section_id: Params.optional.(Params::SoftIdRules),
      )

      FIND_PARAMS = Params.define.(
        id: Params.required.(Params::SoftIdRules),
        project_id: Params.optional.(Params::SoftIdRules),
      )

      CREATE_PARAMS = Params.define.(
        counting_id: Params.required.(Params::IdRules),
        sample_id: Params.required.(Params::IdRules),
        species_id: Params.required.(Params::IdRules),
      )

      UPDATE_PARAMS = Params.define.(
        id: Params.required.(Params::IdRules),
        quantity: Params.optional.(Params.blank_to_nil_or.(Params.integer.(Params.gte.(0)))),
        status: Params.optional.(Params.integer.(Params.included_in.(Paleolog::Occurrence::STATUSES))),
        uncertain: Params.optional.(Params.bool.(Params.any)),
      )

      DELETE_PARAMS = Params.define.(
        id: Params.required.(Params::IdRules),
      )

      def find_all(params)
        parameterize(params, FIND_ALL_PARAMS)
          .and_then { carefully(_1, find_all_occurrences) }
      end

      def find(params)
        authenticate
          .and_then { parameterize(params, FIND_PARAMS) }
          .and_then { carefully(_1, find_occurrence) }
      end

      def create(params)
        parameterize(params, CREATE_PARAMS)
          .and_then { verify(_1, species_uniqueness) }
          .and_then { merge(_1, default_status) }
          .and_then { merge(_1, next_rank) }
          .and_then { carefully(_1, create_occurrence) }
      end

      def update(params)
        parameterize(params, UPDATE_PARAMS)
          .and_then { carefully(_1, update_occurrence) }
      end

      def delete(params)
        parameterize(params, DELETE_PARAMS)
          .and_then { carefully(_1, delete_occurrence) }
      end

      private

      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/AbcSize
      def find_all_occurrences
        lambda do |params|
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
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity

      # rubocop:disable Metrics/AbcSize
      def find_occurrence
        lambda do |params|
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
      end
      # rubocop:enable Metrics/AbcSize

      def create_occurrence
        lambda do |params|
          occurrence_id = db[:occurrences].insert(**params)
          find_occurrence.(id: occurrence_id)
        end
      end

      def update_occurrence
        lambda do |params|
          db[:occurrences].where(id: params[:id]).update(**params)
          find_occurrence.(id: params[:id])
        end
      end

      def delete_occurrence
        lambda do |params|
          db[:occurrences].where(id: params[:id]).delete
        end
      end

      def species_uniqueness
        lambda do |params|
          exists = db[:occurrences].where(
            species_id: params[:species_id],
            counting_id: params[:counting_id],
            sample_id: params[:sample_id],
          ).limit(1).count.positive?

          { species_id: Operation::TAKEN } if exists
        end
      end

      def default_status
        lambda do |_|
          { status: Paleolog::Occurrence::NORMAL }
        end
      end

      def next_rank
        lambda do |params|
          max_rank = db[:occurrences]
                     .where(counting_id: params[:counting_id], sample_id: params[:sample_id])
                     .max(:rank)
          { rank: (max_rank || 0) + 1 }
        end
      end

      # def available_species_ids(counting_id, sample_id, group_id)
      #   used_ids = ds.where(counting_id: counting_id, sample_id: sample_id).map { |result| result[:species_id] }
      #   all = Paleolog::Repo::Species.all_for_group(group_id)
      #   (used_ids.empty? ? all : all.reject { |s| used_ids.include?(s.id) }).sort_by(&:name).map(&:id)
      # end
    end
  end
end
