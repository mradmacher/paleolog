# frozen_string_literal: true

module Paleolog
  module Repository
    class Group < Operation::Base
      CREATE_PARAMS = Params.define.(
        name: Params.required.(Params::NameRules),
      )

      def find_all
        carefully({}, find_groups)
      end

      def create(params)
        parameterize(params, CREATE_PARAMS)
          .and_then { verify(_1, name_uniqueness) }
          .and_then { carefully(_1, create_group) }
      end

      private

      def find_groups
        lambda do |_params|
          db[:groups].all.map { Paleolog::Group.new(**_1) }
        end
      end

      def find_group
        lambda do |params|
          result = db[:groups].where(id: params[:id]).first
          break_with(Operation::NOT_FOUND) unless result

          Paleolog::Group.new(**result)
        end
      end

      def create_group
        lambda do |params|
          group_id = db[:groups].insert(**params)
          find_group.(id: group_id)
        end
      end

      def name_uniqueness
        lambda do |params|
          break unless params.key?(:name)

          { name: Operation::TAKEN } if name_exists?(db[:groups], params)
        end
      end
    end
  end
end
