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
        authenticate(raw_params)
          .and_then { parameterize(raw_params, FIND_PARAMS) }
          .and_then { authorize(_1, can_view(Paleolog::Sample, :id)) }
          .and_then { carefully(_1, find_sample) }
      end

      def create(raw_params)
        authenticate
          .and_then { parameterize(raw_params, CREATE_PARAMS) }
          .and_then { authorize(_1, can_manage(Paleolog::Section, :section_id)) }
          .and_then { verify(_1, name_uniqueness) }
          .and_then { merge(_1, next_rank) }
          .and_then { carefully(_1, create_sample) }
      end

      def update(raw_params)
        authenticate
          .and_then { parameterize(raw_params, UPDATE_PARAMS) }
          .and_then { authorize(_1, can_manage(Paleolog::Sample, :id)) }
          .and_then { verify(_1, name_uniqueness) }
          .and_then { carefully(_1, update_sample) }
      end

      private

      def find_sample
        lambda do |params|
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
      end

      def create_sample
        lambda do |params|
          sample_id = db[:samples].insert(timestamps_for_create.merge(**params))
          find_sample.(id: sample_id)
        end
      end

      def update_sample
        lambda do |params|
          db[:samples].where(id: params[:id]).update(timestamps_for_update.merge(**params))
          find_sample.(id: params[:id])
        end
      end

      def name_uniqueness
        lambda do |params|
          break unless params.key?(:name)

          { name: Operation::TAKEN } if name_exists?(db[:samples], params, scope: :section_id)
        end
      end

      def next_rank
        lambda do |params|
          max_rank = db[:samples].where(section_id: params[:section_id]).max(:rank) || 0
          { rank: max_rank + 1 }
        end
      end
    end
  end
end
