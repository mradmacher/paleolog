# frozen_string_literal: true

module Paleolog
  module Operation
    module CommonValidations
      def name_uniqueness(entity_class)
        lambda do |params|
          break unless params.key?(:name)

          if repo.for(entity_class).similar_name_exists?(
            params[:name],
            exclude_id: params[:id],
          )
            { name: TAKEN }
          end
        end
      end
    end
  end
end
