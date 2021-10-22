# frozen_string_literal: true
module Paleolog
  module Repo
    class Group
      include CommonQueries

      def name_exists?(name)
        ds.where(Sequel.ilike(:name, name.upcase)).limit(1).count > 0
      end

      def entity_class
        Paleolog::Group
      end

      def ds
        Config.db[:groups]
      end

      def use_timestamps?
        false
      end
    end
  end
end
