# frozen_string_literal: true

require 'sinatra/base'
require_relative 'auth_helpers'
require_relative 'path_helpers'
require_relative 'view_helpers'

module Web
  class Species < Sinatra::Base
    helpers Web::AuthHelpers
    helpers Web::PathHelpers
    helpers Web::ViewHelpers

    %w[/species* /projects/:project_id/species* /catalog].each do |pattern|
      before pattern do
        authorize!
      end
    end

    get '/species/search-filters' do
      {
        groups: Paleolog::Repository::Group.new(Paleolog.db, authorizer).find_all.value.map do |group|
          { id: group.id, name: group.name }
        end,
      }.to_json
    end

    get '/catalog' do
      {
        groups: Paleolog::Repository::Group.new(Paleolog.db, authorizer).find_all.value.map do |group|
          { id: group.id, name: group.name }
        end,
        initial: {
          group_id: 1,
        },
      }.to_json
      @filters = {}
      @filters[:group_id] = params[:group_id] if params[:group_id] && !params[:group_id].empty?
      @filters[:name] = params[:name] if params[:name] && !params[:name].empty?
      @filters[:verified] = true if params[:verified] == 'true'

      using_application_layout { display 'catalog.html' }
    end

    get '/species/:id' do
      case Paleolog::Repository::Species.new(Paleolog.db, authorizer).find(id: params[:id])
      in { value: }
        @species = value
        using_species_layout { display 'species/show.html' }
      in { error: }
        redirect_to home_path
      end
    end
  end
end
