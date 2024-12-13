# frozen_string_literal: true

module Paleolog
  module Repository
    class Project < Operation::Base
      FIND_PARAMS = Params.define do |p|
        {
          id: p::REQUIRED.(p::SLUG_ID),
        }
      end

      CREATE_PARAMS = Params.define do |p|
        {
          name: p::REQUIRED.(p::NAME),
          user_id: p::REQUIRED.(p::ID),
        }
      end

      UPDATE_PARAMS = Params.define do |p|
        {
          id: p::REQUIRED.(p::ID),
          name: p::REQUIRED.(p::NAME),
        }
      end

      UPDATE_RESEARCHER_PARAMS = Params.define do |p|
        {
          project_id: p::REQUIRED.(p::ID),
          user_id: p::REQUIRED.(p::ID),
          manager: p::REQUIRED.(p::BOOL),
        }
      end

      REMOVE_RESEARCHER_PARAMS = Params.define do |p|
        {
          project_id: p::REQUIRED.(p::ID),
          user_id: p::REQUIRED.(p::ID),
        }
      end

      def find(raw_params)
        # authenticate
        parameterize(raw_params, FIND_PARAMS)
          .and_then { |params| carefully { find_project(params) } }
      end

      def find_all
        authenticate
          .and_then { carefully { find_projects(authorizer.user_id) } }
      end

      def create(raw_params)
        authenticate
          .and_then { parameterize(raw_params.merge(user_id: authorizer.user_id), CREATE_PARAMS) }
          .and_then { verify_name_uniqueness(_1, db[:projects]) }
          .and_then { |params| carefully { create_project(params) } }
      end

      def rename(raw_params)
        authenticate
          .and_then { parameterize(raw_params, UPDATE_PARAMS) }
          .and_then { authorize(_1, can_manage(Paleolog::Project, :id)) }
          .and_then { verify_name_uniqueness(_1, db[:projects]) }
          .and_then { |params| carefully { update_project(params) } }
      end

      def update_researcher(raw_params)
        parameterize(raw_params, UPDATE_RESEARCHER_PARAMS)
          .and_then { |params| carefully { update_project_researcher(params) } }
      end

      def remove_researcher(raw_params)
        parameterize(raw_params, REMOVE_RESEARCHER_PARAMS)
          .and_then { |params| carefully { remove_project_researcher(params) } }
      end

      private

      WithCountings = lambda do |db, project|
        db[:countings].where(project_id: project.id).all.map do |counting_result|
          project.countings << Paleolog::Counting.new(**counting_result)
        end
      end

      WithSections = lambda do |db, project|
        db[:sections].where(project_id: project.id).each do |section_result|
          project.sections << Paleolog::Section.new(**section_result)
        end
      end

      WithResearchers = lambda do |db, project|
        db[:research_participations].where(project_id: project.id).all.map do |result|
          project.researchers << Paleolog::Researcher.new(**result) do |researcher|
            user_result = db[:users].where(id: researcher.user_id).first
            researcher.user = Paleolog::User.new(**user_result)
          end
        end
      end

      def find_project(params)
        result = db[:projects].where(id: params[:id]).first
        break_with(Operation::NOT_FOUND) unless result

        Paleolog::Project.new(**result) do |project|
          WithCountings.(db, project)
          WithSections.(db, project)
          WithResearchers.(db, project)
        end
      end

      def find_projects(user_id)
        db[:projects]
          .join(:research_participations, Sequel[:research_participations][:project_id] => :id)
          .where(user_id: user_id)
          .reverse_order(:created_at)
          .select_all(:projects)
          .map { Paleolog::Project.new(**_1) }
      end

      def find_researcher(params)
        result = db[:research_participations].where(project_id: params[:project_id], user_id: params[:user_id]).first
        break_with(Operation::NOT_FOUND) unless result

        Paleolog::Researcher.new(**result)
      end

      def update_project_researcher(params)
        db[:research_participations]
          .where(project_id: params[:project_id], user_id: params[:user_id])
          .update(manager: params[:manager])

        find_researcher(project_id: params[:project_id], user_id: params[:user_id])
      end

      def remove_project_researcher(params)
        db[:research_participations]
          .where(project_id: params[:project_id], user_id: params[:user_id])
          .delete
      end

      def update_project(params)
        db[:projects].where(id: params[:id]).update(timestamps_for_update.merge(**params)) unless params.empty?
        find_project(id: params[:id])
      end

      def create_project(params)
        project_id = nil
        db.transaction do
          project_id = db[:projects].insert(
            timestamps_for_create.merge(**params.except(:user_id)),
          )
          db[:research_participations].insert(
            timestamps_for_create.merge(
              user_id: params[:user_id],
              project_id: project_id,
              manager: true,
            ),
          )
        end
        find_project(id: project_id)
      end
    end
  end
end
