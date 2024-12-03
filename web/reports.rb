# frozen_string_literal: true

require 'sinatra/base'
require_relative 'auth_helpers'
require_relative 'path_helpers'
require_relative 'view_helpers'

module Web
  class Reports < Sinatra::Base
    helpers Web::AuthHelpers
    helpers Web::PathHelpers
    helpers Web::ViewHelpers

    before '/projects/:project_id/reports*' do
      authorize!
      @occurrence_operation = Paleolog::Repository::Occurrence.new(Paleolog.db, authorizer)
    end

    get '/projects/:project_id/reports' do
      @project = Paleolog::Repository::Project.new(Paleolog.db, authorizer).find(id: params[:project_id]).value
      if params[:section]
        @section = Paleolog::Repository::Section.new(Paleolog.db, authorizer).find(id: params[:section],
                                                                                   project_id: @project.id,).value
      end
      if params[:counting]
        @counting = Paleolog::Repository::Counting.new(Paleolog.db, authorizer).find(id: params[:counting],
                                                                                     project_id: @project.id,).value
      end
      @groups = Paleolog::Repository::Group.new(Paleolog.db, authorizer).find_all.value
      @fields = Paleolog::Repository::Field.new(Paleolog.db, authorizer).find_all.value
      @occurrences = if @counting && @section
                       @occurrence_operation.find_all(counting_id: @counting.id,
                                                      section_id: @section.id,).value
                     else
                       []
                     end
      @species = @occurrences.map(&:species).uniq(&:id)

      using_project_layout { using_reports_layout { display 'reports/index.html' } }
    end

    post '/projects/:project_id/reports' do
      @project = Paleolog::Repository::Project.new(Paleolog.db, authorizer).find(id: params[:project_id]).value
      if params[:section_id]
        @section = Paleolog::Repository::Section.new(Paleolog.db, authorizer).find(id: params[:section],
                                                                                   project_id: @project.id,).value
      end
      if params[:counting_id]
        @counting = Paleolog::Repository::Counting.new(Paleolog.db, authorizer).find(id: params[:counting],
                                                                                     project_id: @project.id,).value
      end
      @occurrences = if @counting && @section
                       @occurrence_operation.find_all(counting_id: @counting.id,
                                                      section_id: @section.id,).value
                     else
                       []
                     end
      @report = Paleolog::Report.build(params)
      @report.counted_group = @counting.group
      @report.marker = @counting.marker
      @report.marker_quantity = @counting.marker_count
      # def occurrence_density_map(samples, counted_group:, marker:, marker_quantity:)
      @report.generate(@occurrences, @section.samples)
      @chart = Paleolog::Paleorep::ChartView.new(@report)
      using_export_layout { display 'reports/create.html' }
    end

    post '/projects/:project_id/reports/export.csv' do
      @project = Paleolog::Repository::Project.new(Paleolog.db, authorizer).find(id: params[:project_id]).value
      @section = Paleolog::Repository::Section.new(Paleolog.db, authorizer).find(id: params[:section],
                                                                                 project_id: @project.id,).value
      @counting = Paleolog::Repository::Counting.new(Paleolog.db, authorizer).find(id: params[:counting],
                                                                                   project_id: @project.id,).value

      @occurrences = if @counting && @section
                       @occurrence_operation.find_all(counting_id: @counting.id,
                                                      section_id: @section.id,).value
                     else
                       []
                     end
      @report = Paleolog::Report.build(params['report'])
      @report.counted_group = @counting.group
      @report.marker = @counting.marker
      @report.marker_quantity = @counting.marker_count
      @report.generate(@occurrences, @section.samples)
      content_type 'text/csv'
      @report.to_csv
    end
  end
end
