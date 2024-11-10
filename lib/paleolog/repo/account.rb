# frozen_string_literal: true

module Paleolog
  module Repo
    class Account
      class << self
        include CommonQueries

        def similar_name_exists?(name, exclude_id: nil)
          alike_name_exists?(name, exclude_id ? ds.exclude(id: exclude_id) : ds)
        end

        def entity_class
          Paleolog::Account
        end

        def use_timestamps?
          false
        end

        def ds
          Config.db[:accounts]
        end
      end
    end
  end
end
