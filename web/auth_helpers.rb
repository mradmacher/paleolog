# frozen_string_literal: true

module Web
  module AuthHelpers
    UNAUTHORIZED = 401
    FORBIDDEN = 403

    def authorizer
      @authorizer ||= Paleolog::Authorizer.new(session)
    end

    def require_https!
      return unless request.scheme == 'http'

      return unless settings.production?

      headers['Location'] = request.url.sub('http', 'https')
      halt 301
    end

    def logged_in?
      authorizer.logged_in?
    end

    def authorize!
      halt UNAUTHORIZED unless logged_in?
    end
  end
end
