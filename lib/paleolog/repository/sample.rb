# frozen_string_literal: true

module Paleolog
  module Repository
    class Sample < Operation::Base
      FIND_PARAMS = Params.define.(
        id: Params.required.(Params::SoftIdRules),
        project_id: Params.optional.(Params::SoftIdRules),
      )

      CREATE_PARAMS = Params.define.(
        name: Params.required.(Params::NameRules),
        section_id: Params.required.(Params::IdRules),
        description: Params.optional.(Params::DescriptionRules),
        weight: Params.optional.(Params.blank_to_nil_or.(Params.decimal.(Params.gt.(0.0)))),
      )

      UPDATE_PARAMS = Params.define.(
        id: Params.required.(Params::IdRules),
        name: Params.optional.(Params::NameRules),
        description: Params.optional.(Params::DescriptionRules),
        weight: Params.optional.(Params.blank_to_nil_or.(Params.decimal.(Params.gt.(0.0)))),
      )

      def find(raw_params)
        authenticate
          .and_then { parameterize(raw_params, FIND_PARAMS) }
          .and_then { authorize(_1, can_view(Paleolog::Sample, :id)) }
          .and_then { |params| carefully { find_sample(params) } }
      end

      def create(raw_params)
        authenticate
          .and_then { parameterize(raw_params, CREATE_PARAMS) }
          .and_then { authorize(_1, can_manage(Paleolog::Section, :section_id)) }
          .and_then { verify_name_uniqueness(_1, db[:samples], scope: :section_id) }
          .and_then { pass(with_next_rank(_1)) }
          .and_then { |params| carefully { create_sample(params) } }
      end

      def update(raw_params)
        authenticate
          .and_then { parameterize(raw_params, UPDATE_PARAMS) }
          .and_then { authorize(_1, can_manage(Paleolog::Sample, :id)) }
          .and_then { verify_name_uniqueness(_1, db[:samples], scope: :section_id) }
          .and_then { |params| carefully { update_sample(params) } }
      end

      private

      def find_sample(params)
        result = if params[:project_id]
                   db[:samples]
                    .where(Sequel[:samples][:id] => params[:id], Sequel[:projects][:id] => params[:project_id])
                    .join(:sections, Sequel[:sections][:id] => :section_id)
                    .join(:projects, Sequel[:projects][:id] => :project_id)
                    .select_all(:samples)
                    .first
                 else
                   db[:samples].where(id: params[:id]).first
                 end
        break_with(Operation::NOT_FOUND) unless result

        Paleolog::Sample.new(**result)
      end

      def create_sample(params)
        sample_id = db[:samples].insert(timestamps_for_create.merge(**params))
        find_sample(id: sample_id)
      end

      def update_sample(params)
        db[:samples].where(id: params[:id]).update(timestamps_for_update.merge(**params))
        find_sample(id: params[:id])
      end

      def with_next_rank(params)
        max_rank = db[:samples].where(section_id: params[:section_id]).max(:rank) || 0
        params.merge(rank: max_rank + 1)
      end
    end
  end
end
