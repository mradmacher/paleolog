# frozen_string_literal: true

module Paleolog
  module Repo
    class Field
      include CommonQueries

      def all
        ds.all.map { |result|
          Paleolog::Field.new(**result) { |field|
            Paleolog::Repo::Choice.new.all_for_field(field.id).each do |choice|
              field.choices << choice
            end
          }
        }
      end

      def all_for(ids)
        ds.where(id: ids).map do |result|
          Paleolog::Field.new(**result)
        end
      end

      def ds
        Config.db[:fields]
      end

      def entity_class
        Paleolog::Field
      end

      def use_timestamps?
        false
      end
    end
  end
end
