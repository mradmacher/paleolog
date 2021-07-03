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
      "/projects/#{super_id(project)}/occurrences#{details.empty? ? '' : '?' }#{details.join('&')}"
    end

    def reports_path(project, counting: nil, section: nil)
      details = []
      details << "counting=#{super_id(counting)}" if counting
      details << "section=#{super_id(section)}" if section
      "/projects/#{super_id(project)}/reports#{details.empty? ? '' : '?' }#{details.join('&')}"
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

    def occurrence_repository
      @occurrence_repository ||= Paleolog::Repository::Occurrence.new(Paleolog::Repository::Config.db)
    end

    def field_repository
      @field_repository ||= Paleolog::Repository::Field.new(Paleolog::Repository::Config.db)
    end

    def display(view)
      erb view.to_sym
    end

    def using_project_layout
      erb 'project_layout.html'.to_sym, layout: 'application.html'.to_sym do
        yield
      end
    end

    def using_occurrences_layout
      erb 'occurrence_layout.html'.to_sym, layout: nil do
        yield
      end
    end

    def using_reports_layout
      erb 'report_layout.html'.to_sym, layout: nil do
        yield
      end
    end

    def using_export_layout
      erb 'export_layout.html'.to_sym, layout: nil do
        yield
      end
    end

    def using_application_layout
      erb 'application.html'.to_sym, layout: nil do
        yield
      end
    end

    def using_species_layout
      erb 'species_layout.html'.to_sym, layout: 'application.html'.to_sym do
        yield
      end
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

    using_application_layout { display 'catalog.html' }
  end

  get '/species/:id' do
    @species = species_repository.find_with_dependencies(params[:id].to_i)
    using_species_layout { display 'species/show.html' }
    #@commentable = @specimen
    #@comment = Comment.new( :commentable_id => @specimen.id,
    #    :commentable_type => Specimen.to_s,
    #    :user_id => session[:user_id] )
    #@comments = @specimen.comments.all.order('updated_at desc')
  end

  get '/projects' do
    @filters = {}
    @projects = project_repository.all
    using_application_layout { display 'projects/index.html' }
  end

  get '/projects/:id' do
    @project = project_repository.find_with_dependencies(params[:id].to_i)
    using_project_layout { display 'projects/show.html' }
  end

  get '/projects/:project_id/species' do
    @project = project_repository.find_with_dependencies(params[:project_id].to_i)
    @filters = {}
    @filters[:group_id] = params[:group_id] if params[:group_id] && !params[:group_id].empty?
    @filters[:name] = params[:name] if params[:name] && !params[:name].empty?

    @species = species_repository.search_in_project(@project, @filters)
    #@species = species_repository.search_verified(@filters)
    @available_filters = {}
    @available_filters[:groups] = group_repository.all

    using_project_layout { display 'catalog.html' }
  end

  get '/projects/:project_id/species/:id' do
    @project = project_repository.find_with_dependencies(params[:project_id].to_i)
    @species = species_repository.find_with_dependencies(params[:id].to_i)
    using_project_layout {
      #using_species_layout { display 'species/show.html' } }
      erb 'species_layout.html'.to_sym, layout: nil do
        display 'species/show.html'
      end
    }
  end

  get '/projects/:project_id/sections/:id' do
    @project = project_repository.find_with_dependencies(params[:project_id].to_i)
    @section = project_repository.find_section(@project, params[:id].to_i)
    using_project_layout { display 'sections/show.html' }
  end

  get '/projects/:project_id/countings/:id' do
    @project = project_repository.find_with_dependencies(params[:project_id].to_i)
    @counting = project_repository.find_counting(@project, params[:id].to_i)
    using_project_layout { display 'countings/show.html' }
  end

  get '/projects/:project_id/reports' do
    @project = project_repository.find_with_dependencies(params[:project_id].to_i)
    @section = project_repository.find_section(@project, params[:section].to_i) if params[:section]
    @counting = project_repository.find_counting(@project, params[:counting].to_i) if params[:counting]
    @groups = group_repository.all
    @fields = field_repository.all
    @occurrences = @counting && @section ? occurrence_repository.all_for_section(@counting, @section) : []
    @species = @occurrences.map(&:species).uniq(&:id)

    using_project_layout { using_reports_layout { display 'reports/index.html' } }
  end

  post '/projects/:project_id/reports' do
    @project = project_repository.find_with_dependencies(params[:project_id].to_i)
    @report = Paleolog::Report.build(params)
		@report.generate
    @chart = Paleolog::Paleorep::ChartView.new(@report)
    using_export_layout { display 'reports/create.html' }
  end

  #def export
  #  @report = Report.build(params[:report])
	#	@report.generate
  #  respond_to do |format|
  #    format.csv
  #    format.pdf
  #    format.svg
  #    format.html
  #  end
  #end

  get '/projects/:project_id/occurrences' do
    @project = project_repository.find_with_dependencies(params[:project_id].to_i)
    @sample = project_repository.find_sample(@project, params[:sample].to_i) if params[:sample]
    @section = project_repository.find_section(@project, params[:section].to_i) if params[:section]
    @counting = project_repository.find_counting(@project, params[:counting].to_i) if params[:counting]
    if @counting && @sample
      @occurrences = occurrence_repository.all_for_sample(@counting, @sample)
    else
      @occurrences = []
    end
    @counting_summary = Paleolog::CountingSummary.new

    using_project_layout { using_occurrences_layout { display 'occurrences/show.html' } }
  end
end
