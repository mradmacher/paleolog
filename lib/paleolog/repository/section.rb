# frozen_string_literal: true

module Paleolog
  module Repository
    class Section < Operation::Base
      ALL_FOR_PROJECT_PARAMS = Params.define do |p|
        {
          project_id: p::REQUIRED.(p::ID),
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
          name: p::REQUIRED.(p::NAME),
          project_id: p::REQUIRED.(p::ID),
        }
      end

      UPDATE_PARAMS = Params.define do |p|
        {
          id: p::REQUIRED.(p::ID),
          name: p::REQUIRED.(p::NAME),
        }
      end

      def all_for_project(raw_params)
        authenticate
          .and_then { parameterize(raw_params, ALL_FOR_PROJECT_PARAMS) }
          .and_then { authorize(_1, can_view(Paleolog::Project, :project_id)) }
          .and_then { |params| carefully { find_project_sections(params) } }
      end

      def find(raw_params)
        authenticate
          .and_then { parameterize(raw_params, FIND_PARAMS) }
          .and_then { authorize(_1, can_view(Paleolog::Section, :id)) }
          .and_then { |params| carefully { find_section_with_samples(params) } }
      end

      def create(raw_params)
        authenticate
          .and_then { parameterize(raw_params, CREATE_PARAMS) }
          .and_then { authorize(_1, can_manage(Paleolog::Project, :project_id)) }
          .and_then { verify_name_uniqueness(_1, db[:sections], scope: :project_id) }
          .and_then { |params| carefully { create_section(params) } }
      end

      def update(raw_params)
        authenticate
          .and_then { parameterize(raw_params, UPDATE_PARAMS) }
          .and_then { authorize(_1, can_manage(Paleolog::Section, :id)) }
          .and_then { verify_name_uniqueness(_1, db[:sections], scope: :project_id) }
          .and_then { |params| carefully { update_section(params) } }
      end

      private

      def create_section(params)
        section_id = db[:sections].insert(timestamps_for_create.merge(**params))
        find_section_with_samples(id: section_id)
      end

      def update_section(params)
        db[:sections].where(id: params[:id]).update(timestamps_for_update.merge(**params))
        find_section_with_samples(id: params[:id])
      end

      def find_project_sections(params)
        db[:sections].where(project_id: params[:project_id]).all.map do |result|
          Paleolog::Section.new(**result)
        end
      end

      def find_section_with_samples(params)
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
  end
end
