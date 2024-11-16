# frozen_string_literal: true

module Paleolog
  module Repository
    class Project < Operation::Base
      FIND_PARAMS = Params.define.(
        id: Params.required.(Params::SoftIdRules),
      )

      CREATE_PARAMS = Params.define.(
        name: Params.required.(Params::NameRules),
        user_id: Params.required.(Params::IdRules),
      )

      UPDATE_PARAMS = Params.define.(
        id: Params.required.(Params::IdRules),
        name: Params.required.(Params::NameRules),
      )

      UPDATE_RESEARCHER_PARAMS = Params.define.(
        project_id: Params.required.(Params::IdRules),
        user_id: Params.required.(Params::IdRules),
        manager: Params.required.(Params.bool.(Params.any)),
      )

      REMOVE_RESEARCHER_PARAMS = Params.define.(
        project_id: Params.required.(Params::IdRules),
        user_id: Params.required.(Params::IdRules),
      )

      def find(raw_params)
        # authenticate
        parameterize(raw_params, FIND_PARAMS)
          .and_then { carefully(_1, find_project) }
      end

      def find_all
        authenticate
          .and_then { carefully(_1, find_projects(authorizer.user_id)) }
      end

      def create(raw_params)
        authenticate
          .and_then { parameterize(raw_params.merge(user_id: authorizer.user_id), CREATE_PARAMS) }
          .and_then { verify(_1, name_uniqueness) }
          .and_then { carefully(_1, create_project) }
      end

      def rename(raw_params)
        authenticate
          .and_then { parameterize(raw_params, UPDATE_PARAMS) }
          .and_then { authorize(_1, can_manage(Paleolog::Project, :id)) }
          .and_then { verify(_1, name_uniqueness) }
          .and_then { carefully(_1, update_project) }
      end

      def update_researcher(params)
        parameterize(params, UPDATE_RESEARCHER_PARAMS)
          .and_then { carefully(_1, UpdateResearcher.(db)) }
      end

      def remove_researcher(params)
        parameterize(params, REMOVE_RESEARCHER_PARAMS)
          .and_then { carefully(_1, RemoveResearcher.(db)) }
      end

      private

      def with_countings
        lambda do |project|
          db[:countings].where(project_id: project.id).all.map do |counting_result|
            project.countings << Paleolog::Counting.new(**counting_result)
          end
        end
      end

      def with_sections
        lambda do |project|
          db[:sections].where(project_id: project.id).each do |section_result|
            project.sections << Paleolog::Section.new(**section_result)
          end
        end
      end

      def with_researchers
        lambda do |project|
          db[:research_participations].where(project_id: project.id).all.map do |result|
            project.researchers << Paleolog::Researcher.new(**result) do |researcher|
              user_result = db[:users].where(id: researcher.user_id).first
              researcher.user = Paleolog::User.new(**user_result)
            end
          end
        end
      end

      def find_project
        lambda do |params|
          result = db[:projects].where(id: params[:id]).first
          break_with(Operation::NOT_FOUND) unless result

          Paleolog::Project.new(**result) do |project|
            [
              with_countings,
              with_sections,
              with_researchers
            ].each { |opt| opt.call(project) }
          end
        end
      end

      def find_projects(user_id)
        lambda do |_|
          db[:projects]
            .join(:research_participations, Sequel[:research_participations][:project_id] => :id)
            .where(user_id: user_id)
            .reverse_order(:created_at)
            .select_all(:projects)
            .map { Paleolog::Project.new(**_1) }
        end
      end

      FindResearcher = lambda do |db, params|
        result = db[:research_participations].where(project_id: params[:project_id], user_id: params[:user_id]).first
        break_with(Operation::NOT_FOUND) unless result

        Paleolog::Researcher.new(**result)
      end

      UpdateResearcher = lambda do |db, params|
        db[:research_participations]
          .where(project_id: params[:project_id], user_id: params[:user_id])
          .update(manager: params[:manager])

        FindResearcher.(db, project_id: params[:project_id], user_id: params[:user_id])
      end.curry

      RemoveResearcher = lambda do |db, params|
        db[:research_participations]
          .where(project_id: params[:project_id], user_id: params[:user_id])
          .delete
      end.curry

      def update_project
        lambda do |params|
          db[:projects].where(id: params[:id]).update(timestamps_for_update.merge(**params)) unless params.empty?
          find_project.(id: params[:id])
        end
      end

      def create_project
        lambda do |params|
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
          find_project.(id: project_id)
        end
      end

      def name_uniqueness
        lambda do |params|
          break unless params.key?(:name)

          { name: Operation::TAKEN } if name_exists?(db[:projects], params)
        end
      end
    end
  end
end
