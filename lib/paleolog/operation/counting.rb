# frozen_string_literal: true

module Paleolog
  module Operation
    class Counting < BaseOperation
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

      def find(raw_params)
        authenticate
          .and_then { parameterize(raw_params, FIND_PARAMS) }
          .and_then { authorize(_1, can_view(Paleolog::Counting, :id)) }
          .and_then { carefully(_1, ->(params) { repo.find(Paleolog::Counting, params[:id]) }) }
      end

      def create(raw_params)
        authenticate
          .and_then { parameterize(raw_params, CREATE_PARAMS) }
          .and_then { authorize(_1, can_manage(Paleolog::Project, :project_id)) }
          .and_then { verify(_1, name_uniqueness) }
          .and_then { carefully(_1, save_counting) }
      end

      def update(raw_params)
        authenticate
          .and_then { parameterize(raw_params, UPDATE_PARAMS) }
          .and_then { authorize(_1, can_manage(Paleolog::Counting, :id)) }
          .and_then { verify(_1, name_uniqueness) }
          .and_then { carefully(_1, save_counting) }
      end

      private

      def save_counting
        ->(params) { repo.save(Paleolog::Counting.new(**params)) }
      end

      def name_uniqueness
        lambda do |params|
          break unless params.key?(:name)

          if repo.for(Paleolog::Counting).similar_name_exists?(
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
