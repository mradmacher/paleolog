# frozen_string_literal: true

module Paleolog
  module Repository
    class Group < Operation::Base
      CREATE_PARAMS = Params.define.(
        name: Params.required.(Params::NameRules),
      )

      def find_all
        carefully { find_groups }
      end

      def create(raw_params)
        parameterize(raw_params, CREATE_PARAMS)
          .and_then { verify_name_uniqueness(_1, db[:groups]) }
          .and_then { |params| carefully { create_group(params) } }
      end

      private

      def find_groups
        db[:groups].all.map { Paleolog::Group.new(**_1) }
      end

      def find_group(params)
        result = db[:groups].where(id: params[:id]).first
        break_with(Operation::NOT_FOUND) unless result

        Paleolog::Group.new(**result)
      end

      def create_group(params)
        group_id = db[:groups].insert(**params)
        find_group(id: group_id)
      end
    end
  end
end
