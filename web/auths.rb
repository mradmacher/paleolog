# frozen_string_literal: true

require 'sinatra/base'
require_relative 'auth_helpers'
require_relative 'path_helpers'
require_relative 'view_helpers'

module Web
  class Auths < Sinatra::Base
    helpers Web::AuthHelpers
    helpers Web::PathHelpers
    helpers Web::ViewHelpers

    get '/login' do
      using_application_layout { display 'login.html' }
    end

    get '/logout' do
      authorizer.logout
      redirect '/'
    end

    post '/login' do
      authorizer.authorize(params[:login], params[:password])
      redirect '/projects'
      catch Paleolog::Authorizer::InvalidLogin, Paleolog::Authorizer::InvalidPassword
      redirect '/login'
    end
  end
end
