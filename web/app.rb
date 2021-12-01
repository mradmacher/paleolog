# frozen_string_literal: true

$LOAD_PATH << File.join(__dir__, '..', 'lib')

require 'rubygems'
require 'bundler/setup'
require 'sinatra/base'
require 'sinatra/reloader'
require 'redcloth'
require 'paleolog'

# rubocop:disable Metrics/ClassLength
class PaleologWeb < Sinatra::Base
  enable :sessions
  set :static, true
  configure :development do
    register Sinatra::Reloader
  end

  # rubocop:disable Metrics/BlockLength
  helpers do
    def authorizer
      @authorizer ||= Paleolog::Authorizer.new(session)
    end

    def logged_in?
      authorizer.logged_in?
    end

    def authorize(_session)
      # halt 403, '<a href="/login">Login</a>' unless logged_in?
    end

    def parameterize(name)
      name.gsub(/[[:punct:]]/, '-').gsub(/[[:space:]]+/, '-')
      # name.gsub('/', '').gsub(/[[:space:]]+/, '-')
    end

    def super_id(object)
      "#{object.id}-#{parameterize(object.name)}"
    end

    def species_path(species)
      if defined?(@project) && @project
        "/projects/#{super_id(@project)}/species/#{super_id(species)}"
      else
        "/species/#{super_id(species)}"
      end
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

    def project_species_path(project)
      "/projects/#{super_id(project)}/species"
    end

    def counting_section_path(project, counting, section)
      "/projects/#{super_id(project)}/countings/#{super_id(counting)}/sections/#{super_id(section)}"
    end

    def occurrences_path(project, counting: nil, sample: nil, section: nil)
      details = []
      details << "counting=#{super_id(counting)}" if counting
      details << "sample=#{super_id(sample)}" if sample
      details << "section=#{super_id(section)}" if section
      "/projects/#{super_id(project)}/occurrences#{details.empty? ? '' : '?'}#{details.join('&')}"
    end

    def reports_path(project, counting: nil, section: nil)
      details = []
      details << "counting=#{super_id(counting)}" if counting
      details << "section=#{super_id(section)}" if section
      "/projects/#{super_id(project)}/reports#{details.empty? ? '' : '?'}#{details.join('&')}"
    end

    def display(view)
      erb view.to_sym
    end

    def using_project_layout(&block)
      erb :"project_layout.html", layout: :"application.html", &block
    end

    def using_occurrences_layout(&block)
      erb :"occurrence_layout.html", layout: nil, &block
    end

    def using_reports_layout(&block)
      erb :"report_layout.html", layout: nil, &block
    end

    def using_export_layout(&block)
      erb :"export_layout.html", layout: nil, &block
    end

    def using_application_layout(&block)
      erb :"application.html", layout: nil, &block
    end

    def using_species_layout(&block)
      erb :"species_layout.html", layout: :"application.html", &block
    end
  end
  # rubocop:enable Metrics/BlockLength

  %w[/projects* /catalog*].each do |pattern|
    before pattern do
      authorize(session)
    end
  end

  get '/' do
    erb :"home.html", layout: :"application.html"
  end

  get '/login' do
    using_application_layout { display 'login.html' }
  end

  get '/logout' do
    authorizer.logout
    redirect '/'
  end

  post '/login' do
    authorizer.login(params[:login], params[:password])
    redirect '/projects'
    catch Paleolog::Authorizer::InvalidLogin, Paleolog::Authorizer::InvalidPassword
    redirect '/login'
  end

  get '/catalog' do
    @filters = {}
    @filters[:group_id] = params[:group_id] if params[:group_id] && !params[:group_id].empty?
    @filters[:name] = params[:name] if params[:name] && !params[:name].empty?

    @species = Paleolog::Repo::Species.new.search_verified(@filters)
    @available_filters = {}
    @available_filters[:groups] = Paleolog::Repo::Group.new.all

    using_application_layout { display 'catalog.html' }
  end

  get '/species/:id' do
    @species = Paleolog::Repo::Species.new.find(params[:id].to_i)
    using_species_layout { display 'species/show.html' }
  end

  get '/projects' do
    @filters = {}
    @projects = Paleolog::Repo::Project.new.all
    using_application_layout { display 'projects/index.html' }
  end

  get '/projects/:id' do
    @project = Paleolog::Repo::Project.new.find(params[:id].to_i)
    using_project_layout { display 'projects/show.html' }
  end

  get '/projects/:project_id/species' do
    @project = Paleolog::Repo::Project.new.find(params[:project_id].to_i)
    @filters = {}
    @filters[:group_id] = params[:group_id] if params[:group_id] && !params[:group_id].empty?
    @filters[:name] = params[:name] if params[:name] && !params[:name].empty?

    @species = Paleolog::Repo::Species.new.search_in_project(@project, @filters)
    # @species = species_repository.search_verified(@filters)
    @available_filters = {}
    @available_filters[:groups] = Paleolog::Repo::Group.new.all

    using_project_layout { display 'catalog.html' }
  end

  get '/projects/:project_id/species/:id' do
    @project = Paleolog::Repo::Project.new.find(params[:project_id].to_i)
    @species = Paleolog::Repo::Species.new.find(params[:id].to_i)
    using_project_layout do
      # using_species_layout { display 'species/show.html' } }
      erb :"species_layout.html", layout: nil do
        display 'species/show.html'
      end
    end
  end

  get '/projects/:project_id/sections/:id' do
    @project = Paleolog::Repo::Project.new.find(params[:project_id].to_i)
    @section = Paleolog::Repo::Section.new.find_for_project(params[:id].to_i, @project.id)
    using_project_layout { display 'sections/show.html' }
  end

  get '/projects/:project_id/countings/:id' do
    @project = Paleolog::Repo::Project.new.find(params[:project_id].to_i)
    @counting = Paleolog::Repo::Counting.new.find_for_project(params[:id].to_i, @project.id)
    using_project_layout { display 'countings/show.html' }
  end

  get '/projects/:project_id/reports' do
    @project = Paleolog::Repo::Project.new.find(params[:project_id].to_i)
    @section = Paleolog::Repo::Section.new.find_for_project(params[:section].to_i, @project.id) if params[:section]
    @counting = Paleolog::Repo::Counting.new.find_for_project(params[:counting].to_i, @project.id) if params[:counting]
    @groups = Paleolog::Repo::Group.new.all
    @fields = Paleolog::Repo::Field.new.all
    @occurrences = @counting && @section ? Paleolog::Repo::Occurrence.new.all_for_section(@counting, @section) : []
    @species = @occurrences.map(&:species).uniq(&:id)

    using_project_layout { using_reports_layout { display 'reports/index.html' } }
  end

  post '/projects/:project_id/reports' do
    @project = Paleolog::Repo::Project.new.find(params[:project_id].to_i)
    if params[:section_id]
      @section = Paleolog::Repo::Section.new.find_for_project(params[:section_id].to_i,
                                                              @project.id,)
    end
    if params[:counting_id]
      @counting = Paleolog::Repo::Counting.new.find_for_project(params[:counting_id].to_i,
                                                                @project.id,)
    end
    @occurrences = @counting && @section ? Paleolog::Repo::Occurrence.new.all_for_section(@counting, @section) : []
    @report = Paleolog::Report.build(params)
    @report.counted_group = @counting.group
    @report.marker = @counting.marker
    @report.marker_quantity = @counting.marker_count
    # def occurrence_density_map(samples, counted_group:, marker:, marker_quantity:)
    @report.generate(@occurrences, @section.samples)
    @chart = Paleolog::Paleorep::ChartView.new(@report)
    using_export_layout { display 'reports/create.html' }
  end

  # def export
  #   @report = Report.build(params[:report])
  # 	@report.generate
  #   respond_to do |format|
  #     format.csv
  #     format.pdf
  #     format.svg
  #     format.html
  #   end
  # end

  get '/projects/:project_id/occurrences' do
    @project = Paleolog::Repo::Project.new.find(params[:project_id].to_i)
    @section = Paleolog::Repo::Section.new.find_for_project(params[:section].to_i, @project.id) if params[:section]
    @sample = Paleolog::Repo::Sample.new.find_for_section(params[:sample].to_i, @section.id) if params[:sample]
    @counting = Paleolog::Repo::Counting.new.find_for_project(params[:counting].to_i, @project.id) if params[:counting]
    @occurrences = if @counting && @sample
                     Paleolog::Repo::Occurrence.new.all_for_sample(@counting, @sample)
                   else
                     []
                   end
    @counting_summary = Paleolog::CountingSummary.new(@occurrences)
    @density_info = Paleolog::DensityInfo.new(
      counted_group: @counting&.group,
      marker: @counting&.marker,
      marker_quantity: @counting&.marker_count,
    )
    @group_per_gram = @density_info.group_density(@occurrences, @sample)

    using_project_layout { using_occurrences_layout { display 'occurrences/show.html' } }
  end
end
# rubocop:enable Metrics/ClassLength
