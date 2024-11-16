# frozen_string_literal: true

module Paleolog
  module Repository
    class Section < Operation::Base
      ALL_FOR_PROJECT_PARAMS = Params.define.(
        project_id: Params.required.(Params::IdRules),
      )

      FIND_PARAMS = Params.define.(
        id: Params.required.(Params::SoftIdRules),
        project_id: Params.optional.(Params::SoftIdRules),
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
          .and_then { carefully(_1, create_section) }
      end

      def update(raw_params)
        authenticate
          .and_then { parameterize(raw_params, UPDATE_PARAMS) }
          .and_then { authorize(_1, can_manage(Paleolog::Section, :id)) }
          .and_then { verify(_1, name_uniqueness) }
          .and_then { carefully(_1, update_section) }
      end

      private

      def create_section
        lambda do |params|
          section_id = db[:sections].insert(timestamps_for_create.merge(**params))
          find_section_with_samples.(id: section_id)
        end
      end

      def update_section
        lambda do |params|
          db[:sections].where(id: params[:id]).update(timestamps_for_update.merge(**params))
          find_section_with_samples.(id: params[:id])
        end
      end

      def find_project_sections
        lambda do |params|
          db[:sections].where(project_id: params[:project_id]).all.map do |result|
            Paleolog::Section.new(**result)
          end
        end
      end

      def find_section_with_samples
        lambda do |params|
          result = if params[:project_id]
                     db[:sections]
                      .where(
                        Sequel[:sections][:id] => params[:id],
                        Sequel[:projects][:id] => params[:project_id],
                      )
                      .join(:projects, Sequel[:projects][:id] => :project_id)
                      .select_all(:sections)
                      .first
                   else
                     db[:sections].where(id: params[:id]).first
                   end
          break_with(Operation::NOT_FOUND) unless result

          Paleolog::Section.new(**result) do |section|
            db[:samples].where(section_id: section.id).all.map do |sample_result|
              section.samples << Paleolog::Sample.new(**sample_result)
            end
          end
        end
      end

      def name_uniqueness
        lambda do |params|
          break unless params.key?(:name)

          { name: Operation::TAKEN } if name_exists?(db[:sections], params, scope: :project_id)
        end
      end
    end
  end
end
