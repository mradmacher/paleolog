# frozen_string_literal: true

module Web
  module ApiHelpers
    def render_json(result)
      case result
      in { value: }
        [200, yield(value).to_json]
      in { error: }
        if Paleolog::Operation.unauthenticated?(error)
          [401, nil]
        elsif Paleolog::Operation.unauthorized?(error)
          [403, nil]
        elsif Paleolog::Operation.not_found?(error)
          [404, nil]
        else
          [422, { errors: error }.to_json]
        end
      end
    end

    def model_or_errors(result, serializer, name = nil)
      if result.success?
        model_name = name || infer_model_name(result.value.class.name)
        [200, { model_name => serialize_model(result.value, serializer) }.to_json]
      elsif Paleolog::Operation.unauthenticated?(result.error)
        [401, nil]
      elsif Paleolog::Operation.unauthorized?(result.error)
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
