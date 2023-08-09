# frozen_string_literal: true

module Web
  module ApiHelpers
    def model_or_errors(result, serializer, name = nil)
      if result.success?
        model_name = name || infer_model_name(result.value.class.name)
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

    def infer_model_name(class_name)
      class_name.split('::').last.downcase.to_sym
    end

    def serialize_model(model, serializer)
      model.is_a?(Array) ? model.map { |m| serializer.call(m) } : serializer.call(model)
    end
  end
end
