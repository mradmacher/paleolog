# frozen_string_literal: true

module Paleolog
  module Repo
    class Choice
      include CommonQueries

      def all_for(ids)
        result = ds.where(id: ids)
        field_ids = result.map { |r| r[:field_id] }.uniq
        fields = Paleolog::Repo::Field.new.all_for(field_ids)
        result.map do |r|
          Paleolog::Choice.new(**r) do |choice|
            choice.field = fields.detect { |f| f.id == choice.field_id }
          end
        end
      end

      def all_for_field(field_id)
        ds.where(field_id: field_id).all.map do |result|
          Paleolog::Choice.new(**result)
        end
      end

      def name_exists_within_field?(name, field_id)
        ds.where(field_id: field_id).where(Sequel.ilike(:name, name.upcase)).limit(1).count.positive?
      end

      def entity_class
        Paleolog::Choice
      end

      def ds
        Config.db[:choices]
      end

      def use_timestamps?
        false
      end
    end
  end
end
