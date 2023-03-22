# frozen_string_literal: true

module Web
  module ApiHelpers
    def model_or_errors(model, errors, serializer)
      if errors.empty?
        model_name = model.class.name.split('::').last.downcase.to_sym
        [200, { model_name => serializer.call(model) }.to_json]
      elsif errors[:general] == Paleolog::Operation::UNAUTHENTICATED
        [401, nil]
      elsif errors[:general] == Paleolog::Operation::UNAUTHORIZED
        [403, nil]
      else
        [422, { errors: errors }.to_json]
      end
    end
  end
end
