# frozen_string_literal: true

module Paleolog
  module Operation
    class Section < BaseOperation
      ALL_FOR_PROJECT_PARAMS = Params.define.(
        project_id: Params.required.(Params::IdRules),
      )

      FIND_PARAMS = Params.define.(
        id: Params.required.(Params::IdRules),
      )

      CREATE_PARAMS = Params.define.(
        name: Params.required.(Params::NameRules),
        project_id: Params.required.(Params::IdRules),
      )

      UPDATE_PARAMS = Params.define.(
        id: Params.required.(Params::IdRules),
        name: Params.required.(Params::NameRules),
      )

      def all_for_project(raw_params)
        authenticate
          .and_then { parameterize(raw_params, ALL_FOR_PROJECT_PARAMS) }
          .and_then { authorize(_1, can_view(Paleolog::Project, :project_id)) }
          .and_then { carefully(_1, find_project_sections) }
      end

      def find(raw_params)
        authenticate
          .and_then { parameterize(raw_params, FIND_PARAMS) }
          .and_then { authorize(_1, can_view(Paleolog::Section, :id)) }
          .and_then { carefully(_1, find_section_with_samples) }
      end

      def create(raw_params)
        authenticate
          .and_then { parameterize(raw_params, CREATE_PARAMS) }
          .and_then { authorize(_1, can_manage(Paleolog::Project, :project_id)) }
          .and_then { verify(_1, name_uniqueness) }
          .and_then { carefully(_1, save_section) }
      end

      def update(raw_params)
        authenticate
          .and_then { parameterize(raw_params, UPDATE_PARAMS) }
          .and_then { authorize(_1, can_manage(Paleolog::Section, :id)) }
          .and_then { verify(_1, name_uniqueness) }
          .and_then { carefully(_1, save_section) }
      end

      private

      def save_section
        ->(params) { repo.save(Paleolog::Section.new(**params)) }
      end

      def find_project_sections
        lambda do |params|
          repo.for(Paleolog::Section).all_for_project(params[:project_id])
        end
      end

      def find_section_with_samples
        lambda do |params|
          repo.for(Paleolog::Section).find(
            params[:id],
            Paleolog::Repo::Section.with_samples,
          )
        end
      end

      def name_uniqueness
        lambda do |params|
          break unless params.key?(:name)

          if repo.for(Paleolog::Section).similar_name_exists?(
            params[:name],
            project_id: params[:project_id],
            exclude_id: params[:id],
          )
            { name: TAKEN }
          end
        end
      end
    end
  end
end
