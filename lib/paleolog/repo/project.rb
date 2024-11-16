# frozen_string_literal: true

module Paleolog
  module Repo
    class Project
      class << self
        include CommonQueries

        def similar_name_exists?(name, exclude_id: nil)
          (exclude_id ? ds.exclude(id: exclude_id) : ds)
            .where(Sequel.ilike(:name, name.upcase)).limit(1).count.positive?
        end

        def entity_class
          Paleolog::Project
        end

        def ds
          Config.db[:projects]
        end
      end
    end
  end
end
