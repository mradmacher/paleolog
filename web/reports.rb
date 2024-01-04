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
    end

    get '/projects/:project_id/reports' do
      @project = Paleolog::Repo::Project.find(
        params[:project_id].to_i,
        Paleolog::Repo::Project.with_countings,
        Paleolog::Repo::Project.with_sections,
        Paleolog::Repo::Project.with_researchers,
      )
      @section = Paleolog::Repo::Section.find_for_project(params[:section].to_i, @project.id) if params[:section]
      if params[:counting]
        @counting = Paleolog::Repo::Counting.find_for_project(params[:counting].to_i,
                                                              @project.id,)
      end
      @groups = Paleolog::Repo::Group.all
      @fields = Paleolog::Repo::Field.all
      @occurrences = @counting && @section ? Paleolog::Repo::Occurrence.all_for_section(@counting.id, @section.id) : []
      @species = @occurrences.map(&:species).uniq(&:id)

      using_project_without_sidebar_layout { using_reports_layout { display 'reports/index.html' } }
    end

    post '/projects/:project_id/reports' do
      @project = Paleolog::Repo::Project.find(
        params[:project_id].to_i,
        Paleolog::Repo::Project.with_countings,
        Paleolog::Repo::Project.with_sections,
        Paleolog::Repo::Project.with_researchers,
      )
      if params[:section_id]
        @section = Paleolog::Repo::Section.find_for_project(params[:section_id].to_i,
                                                            @project.id,)
      end
      if params[:counting_id]
        @counting = Paleolog::Repo::Counting.find_for_project(params[:counting_id].to_i,
                                                              @project.id,)
      end
      @occurrences = @counting && @section ? Paleolog::Repo::Occurrence.all_for_section(@counting.id, @section.id) : []
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
      @project = Paleolog::Repo::Project.find(
        params[:project_id].to_i,
        Paleolog::Repo::Project.with_countings,
        Paleolog::Repo::Project.with_sections,
        Paleolog::Repo::Project.with_researchers,
      )
      @section = Paleolog::Repo::Section.find_for_project(params['report']['section_id'].to_i, @project.id)
      @counting = Paleolog::Repo::Counting.find_for_project(params['report']['counting_id'].to_i, @project.id)

      @occurrences = @counting && @section ? Paleolog::Repo::Occurrence.all_for_section(@counting.id, @section.id) : []
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
