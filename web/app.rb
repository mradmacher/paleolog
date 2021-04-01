# frozen_string_literal: true

$LOAD_PATH << File.join(__dir__, '..', 'lib')

require 'rubygems'
require 'bundler/setup'
require 'sinatra/base'
require 'sinatra/reloader'
require 'redcloth'
require 'paleolog'

class PaleologWeb < Sinatra::Base
  set :static, true
  configure :development do
    register Sinatra::Reloader
  end

  helpers do
    def parameterize(name)
      name.gsub(/[[:punct:]]/, '-').gsub(/[[:space:]]+/, '-')
      #name.gsub('/', '').gsub(/[[:space:]]+/, '-')
    end

    def super_id(object)
      "#{object.id}-#{parameterize(object.name)}"
    end

    def species_path(species)
      "/species/#{super_id(species)}"
    end

    def project_path(project)
      "/projects/#{super_id(project)}"
    end

    def section_path(project, section)
      "/projects/#{super_id(project)}/sections/#{super_id(section)}"
    end

    def counting_path(project, counting)
      "/projects/#{super_id(project)}/countings/#{super_id(counting)}"
    end

    def counting_section_path(project, counting, section)
      "/projects/#{super_id(project)}/countings/#{super_id(counting)}/sections/#{super_id(section)}"
    end

    def occurrences_path(project, counting: nil, sample: nil, section: nil)
      details = []
      details << "counting=#{super_id(counting)}" if counting
      details << "sample=#{super_id(sample)}" if sample
      details << "section=#{super_id(section)}" if section
      "/projects/#{super_id(project)}/occurrences#{details.empty? ? '' : '?' }#{details.join('&')}"
    end

    def species_repository
      @species_repository ||= Paleolog::Repository::Species.new(Paleolog::Repository::Config.db)
    end

    def group_repository
      @group_repository ||= Paleolog::Repository::Group.new(Paleolog::Repository::Config.db)
    end

    def project_repository
      @project_repository ||= Paleolog::Repository::Project.new(Paleolog::Repository::Config.db)
    end
  end

  get '/' do
    erb 'home.html'.to_sym, layout: 'application.html'.to_sym
  end

  get '/catalog' do
    @filters = {}
    @filters[:group_id] = params[:group_id] if params[:group_id] && !params[:group_id].empty?
    @filters[:name] = params[:name] if params[:name] && !params[:name].empty?

    @species = species_repository.search_verified(@filters)
    @available_filters = {}
    @available_filters[:groups] = group_repository.all

    erb 'catalog.html'.to_sym, layout: 'application.html'.to_sym
  end

  get '/species/:id' do
    @species = species_repository.find_with_dependencies(params[:id].to_i)
    erb 'species_layout.html'.to_sym, layout: 'application.html'.to_sym do
      erb 'species/show.html'.to_sym
    end
    #@commentable = @specimen
    #@comment = Comment.new( :commentable_id => @specimen.id,
    #    :commentable_type => Specimen.to_s,
    #    :user_id => session[:user_id] )
    #@comments = @specimen.comments.all.order('updated_at desc')
  end

  get '/projects' do
    @filters = {}
    @projects = project_repository.all
    erb 'projects/index.html'.to_sym, layout: 'application.html'.to_sym
  end

  get '/projects/:id' do
    @project = project_repository.find_with_dependencies(params[:id].to_i)
    erb 'project_layout.html'.to_sym, layout: 'application.html'.to_sym do
      erb 'projects/show.html'.to_sym
    end
  end

  get '/projects/:project_id/sections/:id' do
    @project = project_repository.find_with_dependencies(params[:project_id].to_i)
    @section = project_repository.find_section(@project, params[:id].to_i)
    erb 'project_layout.html'.to_sym, layout: 'application.html'.to_sym do
      erb 'sections/show.html'.to_sym
    end
  end

  get '/projects/:project_id/countings/:id' do
    @project = project_repository.find_with_dependencies(params[:project_id].to_i)
    @counting = project_repository.find_counting(@project, params[:id].to_i)
    erb 'project_layout.html'.to_sym, layout: 'application.html'.to_sym do
      erb 'countings/show.html'.to_sym
    end
  end

  get '/projects/:project_id/occurrences' do
    @project = project_repository.find_with_dependencies(params[:project_id].to_i)
    @sample = project_repository.find_sample(@project, params[:sample].to_i) if params[:sample]
    @section = project_repository.find_section(@project, params[:section].to_i) if params[:section]
    @counting = project_repository.find_counting(@project, params[:counting].to_i) if params[:counting]
    erb 'project_layout.html'.to_sym, layout: 'application.html'.to_sym do
      erb 'occurrences/show.html'.to_sym
    end
  end

=begin
  def new
    @specimen = Specimen.new
  end

  def edit
    @specimen = Specimen.find(params[:id])
  end

  def create
    @specimen = Specimen.new(specimen_params)

    if @specimen.save
      flash[:notice] = 'Specimen was successfully created.'
      redirect_to(@specimen)
    else
      render :action => "new"
    end
  end

  def update
    @specimen = Specimen.find(params[:id])
    if @specimen.update_attributes(specimen_params)
      flash[:notice] = 'Specimen was successfully updated.'
      redirect_to(@specimen)
    else
      render :action => "edit"
    end
  end

  def destroy
    @specimen = Specimen.find(params[:id])
    @specimen.destroy
    redirect_to specimens_url
  end

  def specimen_params
    params.require(:specimen).permit(
      :name,
      :verified,
      :description,
      :environmental_preferences,
      :group_id
    )
  end
=end
end
