# frozen_string_literal: true

module Paleolog
  module Repository
    class Field < Operation::Base
      CREATE_FIELD_PARAMS = Params.define.(
        name: Params.required.(Params::NameRules),
        group_id: Params.required.(Params::IdRules),
      )

      CREATE_CHOICE_PARAMS = Params.define.(
        name: Params.required.(Params::NameRules),
        field_id: Params.required.(Params::IdRules),
      )

      def find_all
        carefully({}, find_fields)
      end

      def create(params)
        parameterize(params, CREATE_FIELD_PARAMS)
          .and_then { verify(_1, field_name_uniqueness) }
          .and_then { carefully(_1, create_field) }
      end

      def add_choice(params)
        parameterize(params, CREATE_CHOICE_PARAMS)
          .and_then { verify(_1, choice_name_uniqueness) }
          .and_then { carefully(_1, create_choice) }
      end

      private

      def find_choice
        lambda do |params|
          result = db[:choices].where(id: params[:id]).first
          break_with(Operation::NOT_FOUND) unless result

          Paleolog::Choice.new(**result)
        end
      end

      def find_field
        lambda do |params|
          result = db[:fields].where(id: params[:id]).first
          break_with(Operation::NOT_FOUND) unless result

          Paleolog::Field.new(**result) do |field|
            with_choices.(field)
          end
        end
      end

      def with_choices
        lambda do |field|
          db[:choices].where(field_id: field.id).all.map do |choice_result|
            field.choices << Paleolog::Choice.new(**choice_result)
          end
        end
      end

      def find_fields
        lambda do |_|
          db[:fields].all.map do |result|
            Paleolog::Field.new(**result) do |field|
              with_choices.(field)
            end
          end
        end
      end

      def create_field
        lambda do |params|
          field_id = db[:fields].insert(**params)
          find_field.(id: field_id)
        end
      end

      def field_name_uniqueness
        lambda do |params|
          break unless params.key?(:name)

          { name: Operation::TAKEN } if name_exists?(db[:fields], params)
        end
      end

      def create_choice
        lambda do |params|
          choice_id = db[:choices].insert(**params)
          find_choice.(id: choice_id)
        end
      end

      def choice_name_uniqueness
        lambda do |params|
          break unless params.key?(:name)

          { name: Operation::TAKEN } if name_exists?(db[:choices], params, scope: :field_id)
        end
      end
    end
  end
end
