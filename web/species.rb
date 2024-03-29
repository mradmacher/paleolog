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
        groups: Paleolog::Repo::Group.all.map { |group| { id: group.id, name: group.name } },
      }.to_json
    end

    get '/catalog' do
      {
        groups: Paleolog::Repo::Group.all.map { |group| { id: group.id, name: group.name } },
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
      @species = Paleolog::Repo::Species.find(params[:id].to_i)
      using_species_layout { display 'species/show.html' }
    end
  end
end
