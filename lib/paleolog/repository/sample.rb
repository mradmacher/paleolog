# frozen_string_literal: true

module Paleolog
  module Repository
    class Sample < Operation::Base
      FIND_PARAMS = Params.define do |p|
        {
          id: p::REQUIRED.(p::SLUG_ID),
          project_id: p::OPTIONAL.(p::SLUG_ID),
        }
      end

      CREATE_PARAMS = Params.define do |p|
        {
          name: p::REQUIRED.(p::NAME),
          section_id: p::REQUIRED.(p::ID),
          description: p::OPTIONAL.(p::DESCRIPTION),
          weight: p::OPTIONAL.(p::BLANK_TO_NIL_OR.(p::ALL_OF.([p::DECIMAL, p::GT.(0.0)]))),
        }
      end

      UPDATE_PARAMS = Params.define do |p|
        {
          id: p::REQUIRED.(p::ID),
          name: p::OPTIONAL.(p::NAME),
          description: p::OPTIONAL.(p::DESCRIPTION),
          weight: p::OPTIONAL.(p::BLANK_TO_NIL_OR.(p::ALL_OF.([p::DECIMAL, p::GT.(0.0)]))),
        }
      end

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
