# frozen_string_literal: true

module Paleolog
  module Operation
    class Counting < BaseOperation
      FIND_RULES = Pp.define.(
        id: Pp.required.(IdRules),
      )

      CREATE_RULES = Pp.define.(
        name: Pp.required.(NameRules),
        project_id: Pp.required.(IdRules),
      )

      UPDATE_RULES = Pp.define.(
        id: Pp.required.(IdRules),
        name: Pp.required.(NameRules),
      )

      def find(raw_params)
        authenticate
          .and_then { parameterize(raw_params, FIND_RULES) }
          .and_then { authorize(_1, can_view(Paleolog::Counting, :id)) }
          .and_then {
            carefully(_1, ->(params) { repo.for(Paleolog::Counting).find(params[:id]) })
          }
      end

      def create(raw_params)
        authenticate
          .and_then { parameterize(raw_params, CREATE_RULES) }
          .and_then { authorize(_1, can_manage(Paleolog::Project, :project_id)) }
          .and_then { verify(_1, name_uniqueness) }
          .and_then {
            carefully(_1, ->(params) { repo.for(Paleolog::Counting).create(params) })
          }
      end

      def update(raw_params)
        authenticate
          .and_then { parameterize(raw_params, UPDATE_RULES) }
          .and_then { authorize(_1, can_manage(Paleolog::Counting, :id)) }
          .and_then { verify(_1, name_uniqueness) }
          .and_then {
            carefully(_1, ->(params) { repo.for(Paleolog::Counting).update(params[:id], params.except(:id)) })
          }
      end

      private

      def name_uniqueness
        lambda do |params|
          break unless params.key?(:name)

          if repo.for(Paleolog::Counting).similar_name_exists?(
            params[:name],
            project_id: params[:project_id],
            exclude_id: params[:id],
          )
            { name: :taken }
          end
        end
      end
    end
  end
end
