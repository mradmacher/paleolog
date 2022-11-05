# frozen_string_literal: true

module Paleolog
  module Repo
    class Field
      class << self
        include CommonQueries

        def all
          ds.all.map do |result|
            Paleolog::Field.new(**result) do |field|
              Paleolog::Repo::Choice.all_for_field(field.id).each do |choice|
                field.choices << choice
              end
            end
          end
        end

        def all_for(ids)
          ds.where(id: ids).map do |result|
            Paleolog::Field.new(**result)
          end
        end

        def name_exists?(name)
          ds.where(Sequel.ilike(:name, name.upcase)).limit(1).count.positive?
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
end
