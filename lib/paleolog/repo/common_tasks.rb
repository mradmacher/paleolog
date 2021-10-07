# frozen_string_literal: true

module Paleolog
  module Repo
    module CommonTasks
      def remove_all
        entity.dataset.delete
      end

      def create(attributes)
        entity.create(attributes)
      end

      def update(id, attributes)
        entity.with_pk(id).update(attributes)
      end

      def find_by_id(id)
        entity[id]
      end

      def find_all
        entity.dataset.all
      end
    end
  end
end
