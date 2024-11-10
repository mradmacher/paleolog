# frozen_string_literal: true

module Paleolog
  module Operation
    class Project < BaseOperation
      include Operation::CommonValidations

      CREATE_PARAMS = Params.define.(
        name: Params.required.(Params::NameRules),
        user_id: Params.required.(Params::IdRules),
        account_id: Params.required.(Params::IdRules),
      )

      UPDATE_PARAMS = Params.define.(
        id: Params.required.(Params::IdRules),
        name: Params.required.(Params::NameRules),
      )

      def find_all
        authenticate
          .and_then { carefully(_1, find_projects(authorizer.user_id)) }
      end

      def create(raw_params)
        authenticate
          .and_then { parameterize(raw_params.merge(user_id: authorizer.user_id), CREATE_PARAMS) }
          .and_then { verify(_1, name_uniqueness(Paleolog::Project)) }
          .and_then { carefully(_1, create_project) }
      end

      def rename(raw_params)
        authenticate
          .and_then { parameterize(raw_params, UPDATE_PARAMS) }
          .and_then { authorize(_1, can_manage(Paleolog::Project, :id)) }
          .and_then { verify(_1, name_uniqueness(Paleolog::Project)) }
          .and_then { carefully(_1, update_project) }
      end

      private

      def ds_projects
        Repo::Config.db[:projects]
      end

      def ds_accounts
        Repo::Config.db[:accounts]
      end

      def find_projects(user_id)
        lambda do |_|
          result = ds_projects
            .join(:research_participations, Sequel[:research_participations][:project_id] => :id)
            .where(Sequel[:research_participations][:user_id] => user_id)
            .select_all(:projects)
          account_ids = result.map { _1[:account_id] }.uniq
          accounts = ds_accounts.where(id: account_ids).all.map { Paleolog::Account.new(**_1) }
          result.map do
            Paleolog::Project.new(**_1) do |project|
              project.account = accounts.detect { |account| account.id == project.account_id }
            end
          end
        end
      end

      def update_project
        lambda do |params|
          repo.find(
            Paleolog::Project,
            repo.save(Paleolog::Project.new(**params)),
          )
        end
      end

      def create_project
        lambda do |params|
          project_id = nil
          repo.with_transaction do
            project_id = repo.save(Paleolog::Project.new(**params.except(:user_id)))
            repo.save(
              Paleolog::Researcher.new(
                user_id: params[:user_id],
                project_id: project_id,
                manager: true,
              ),
            )
          end
          repo.find(Paleolog::Project, project_id)
        end
      end
    end
  end
end
