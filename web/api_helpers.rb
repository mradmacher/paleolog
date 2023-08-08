# frozen_string_literal: true

module Web
  module ApiHelpers
    def model_or_errors(result, serializer, name = nil)
      if result.success?
        model_name = name || result.value.class.name.split('::').last.downcase.to_sym
        [200, { model_name => serialize_model(result.value, serializer) }.to_json]
      elsif result.error[:general] == Paleolog::Operation::UNAUTHENTICATED
        [401, nil]
      elsif result.error[:general] == Paleolog::Operation::UNAUTHORIZED
        [403, nil]
      else
        [422, { errors: result.error }.to_json]
      end
    end

    private

    def serialize_model(model, serializer)
      model.is_a?(Array) ? model.map { |m| serializer.call(m) } : serializer.call(model)
    end
  end
end
