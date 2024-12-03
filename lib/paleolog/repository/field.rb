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
        carefully { find_fields }
      end

      def create(raw_params)
        parameterize(raw_params, CREATE_FIELD_PARAMS)
          .and_then { verify_name_uniqueness(_1, db[:fields]) }
          .and_then { |params| carefully { create_field(params) } }
      end

      def add_choice(raw_params)
        parameterize(raw_params, CREATE_CHOICE_PARAMS)
          .and_then { verify_name_uniqueness(_1, db[:choices], scope: :field_id) }
          .and_then { |params| carefully { create_choice(params) } }
      end

      private

      WithChoices = lambda do |db, field|
        db[:choices].where(field_id: field.id).all.map do |choice_result|
          field.choices << Paleolog::Choice.new(**choice_result)
        end
      end

      def find_choice(params)
        result = db[:choices].where(id: params[:id]).first
        break_with(Operation::NOT_FOUND) unless result

        Paleolog::Choice.new(**result)
      end

      def find_field(params)
        result = db[:fields].where(id: params[:id]).first
        break_with(Operation::NOT_FOUND) unless result

        Paleolog::Field.new(**result) do |field|
          WithChoices.(db, field)
        end
      end

      def find_fields
        db[:fields].all.map do |result|
          Paleolog::Field.new(**result) do |field|
            WithChoices.(db, field)
          end
        end
      end

      def create_field(params)
        field_id = db[:fields].insert(**params)
        find_field(id: field_id)
      end

      def create_choice(params)
        choice_id = db[:choices].insert(**params)
        find_choice(id: choice_id)
      end
    end
  end
end
