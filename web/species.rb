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

    get '/species/search-filters' do
      {
        groups: Paleolog::Repo::Group.all.map { |group| { id: group.id, name: group.name } },
      }.to_json
    end

    get '/species' do
      filters = {}
      filters[:group_id] = params[:group_id] if params[:group_id] && !params[:group_id].empty?
      filters[:name] = params[:name] if params[:name] && !params[:name].empty?

      result = filters.empty? ? [] : Paleolog::Repo::Species.search(filters)

      {
        filters: filters,
        result: result.map { |r| { id: r.id, name: r.name, group_name: r.group.name } }
      }.to_json
    end

    get '/catalog' do
      @filters = {}
      @filters[:group_id] = params[:group_id] if params[:group_id] && !params[:group_id].empty?
      @filters[:name] = params[:name] if params[:name] && !params[:name].empty?

      @species = Paleolog::Repo::Species.search_verified(@filters)
      @available_filters = {}
      @available_filters[:groups] = Paleolog::Repo::Group.all

      using_application_layout { display 'catalog.html' }
    end

    get '/species/:id' do
      @species = Paleolog::Repo::Species.find(params[:id].to_i)
      using_species_layout { display 'species/show.html' }
    end

    get '/projects/:project_id/species' do
      @project = Paleolog::Repo::Project.find(params[:project_id].to_i)
      @filters = {}
      @filters[:group_id] = params[:group_id] if params[:group_id] && !params[:group_id].empty?
      @filters[:name] = params[:name] if params[:name] && !params[:name].empty?

      @species = Paleolog::Repo::Species.search_in_project(@project, @filters)
      # @species = species_repository.search_verified(@filters)
      @available_filters = {}
      @available_filters[:groups] = Paleolog::Repo::Group.all

      using_project_layout { display 'catalog.html' }
    end

    get '/projects/:project_id/species/:id' do
      @project = Paleolog::Repo::Project.find(params[:project_id].to_i)
      @species = Paleolog::Repo::Species.find(params[:id].to_i)
      using_project_layout do
        # using_species_layout { display 'species/show.html' } }
        erb :"species_layout.html", layout: nil do
          display 'species/show.html'
        end
      end
    end
  end
end
