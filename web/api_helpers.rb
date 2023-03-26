# frozen_string_literal: true

module Web
  module ApiHelpers
    def model_or_errors(model, errors, serializer, name = nil)
      if errors.empty?
        model_name = name || model.class.name.split('::').last.downcase.to_sym
        [200, { model_name => serialize_model(model, serializer) }.to_json]
      elsif errors[:general] == Paleolog::Operation::UNAUTHENTICATED
        [401, nil]
      elsif errors[:general] == Paleolog::Operation::UNAUTHORIZED
        [403, nil]
      else
        [422, { errors: errors }.to_json]
      end
    end

    private

    def serialize_model(model, serializer)
      model.is_a?(Array) ? model.map { |m| serializer.call(m) } : serializer.call(model)
    end
  end
end
