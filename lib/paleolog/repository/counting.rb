# frozen_string_literal: true

module Paleolog
  module Repository
    class Counting < Operation::Base
      FIND_PARAMS = Params.define.(
        id: Params.required.(Params::SoftIdRules),
        project_id: Params.optional.(Params::SoftIdRules),
      )

      CREATE_PARAMS = Params.define.(
        project_id: Params.required.(Params::IdRules),
        name: Params.required.(Params::NameRules),
        marker_id: Params.optional.(Params::IdRules),
        group_id: Params.optional.(Params::IdRules),
      )

      UPDATE_PARAMS = Params.define.(
        id: Params.required.(Params::IdRules),
        name: Params.optional.(Params::NameRules),
        marker_id: Params.optional.(Params::IdRules),
        group_id: Params.optional.(Params::IdRules),
      )

      def find(raw_params)
        authenticate
          .and_then { parameterize(raw_params, FIND_PARAMS) }
          .and_then { authorize(_1, can_view(Paleolog::Counting, :id)) }
          .and_then { |params| carefully { find_counting(params) } }
      end

      def create(raw_params)
        authenticate
          .and_then { parameterize(raw_params, CREATE_PARAMS) }
          .and_then { authorize(_1, can_manage(Paleolog::Project, :project_id)) }
          .and_then { verify_name_uniqueness(_1, db[:countings], scope: :project_id) }
          .and_then { |params| carefully { create_counting(params) } }
      end

      def update(raw_params)
        authenticate
          .and_then { parameterize(raw_params, UPDATE_PARAMS) }
          .and_then { authorize(_1, can_manage(Paleolog::Counting, :id)) }
          .and_then { verify_name_uniqueness(_1, db[:countings], scope: :project_id) }
          .and_then { |params| carefully { update_counting(params) } }
      end

      private

      def find_counting(params)
        result = if params[:project_id]
                   db[:countings]
                    .where(Sequel[:countings][:id] => params[:id], Sequel[:projects][:id] => params[:project_id])
                    .join(:projects, Sequel[:projects][:id] => :project_id)
                    .select_all(:countings)
                    .first
                 else
                   db[:countings].where(id: params[:id]).first
                 end
        break_with(Operation::NOT_FOUND) unless result

        Paleolog::Counting.new(**result) do |counting|
          counting.group = Paleolog::Group.new(**db[:groups].where(id: counting.group_id).first) if result[:group_id]
          if result[:marker_id]
            counting.marker = Paleolog::Species.new(**db[:species].where(id: counting.marker_id).first)
          end
        end
      end

      def create_counting(params)
        counting_id = db[:countings].insert(**params)
        find_counting(id: counting_id)
      end

      def update_counting(params)
        db[:countings].where(id: params[:id]).update(**params)
        find_counting(id: params[:id])
      end
    end
  end
end
